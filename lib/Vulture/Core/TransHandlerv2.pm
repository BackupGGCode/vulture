#file:Core/TransHandlerv2.pm
#-------------------------
package Core::TransHandlerv2;

use Apache2::RequestRec ();
use Apache2::RequestIO ();
use Apache2::Request;

use Apache2::Reload;
use Apache2::Log;

use Apache2::Const -compile => qw(OK DECLINED FORBIDDEN REDIRECT DONE);

use Core::VultureUtils qw(&get_app &get_intf &version_check &get_cookie &session);

use Core::Log;
use Apache::SSLLookup;

use DBI;

use Module::Load;

sub handler {
	my $r = Apache::SSLLookup->new(shift);
	my $uri = $r->uri;
	my $unparsed_uri = $r->unparsed_uri;
	my $protocol = $r->protocol();
	my $dbh = DBI->connect($r->dir_config('VultureDSNv3'));

    #Calling log functions
	my $log = Core::Log->new($r);

	#Sending db handler to next Apache Handlers
	$r->pnotes('dbh' => $dbh);
	$r->pnotes('log' => $log);

	$log->debug("########## TransHandler ##########");

	#Version check
	if (!version_check($dbh, $log)){
		$log->error("Database version is not up-to-date. Can't load Vulture. Please check versions");
		return Apache2::Const::FORBIDDEN;	
	} else {
		$log->debug("Your Vulture is up-to-date. Congratulations !");	
	}

	#If protocol is different from HTTP or HTTPS, reject the connexion
	if ($protocol !~ /HTTP/ and $protocol !~ /HTTPS/){
	    $log->error("Rejecting bad protocol $protocol");
		return Apache2::Const::FORBIDDEN;	
	}

	#If URI matches with app adress, get app and interface
	my $app = get_app($log, $r->hostname, $dbh, $r->dir_config('VultureID')) if ($r->unparsed_uri !~ /vulture_app/ and $r->unparsed_uri !~ /vulture_logout/);
	$r->pnotes('app' => $app) if defined $app;

	#Plugin or Rewrite (according to URI)
	my $plugins = $dbh->selectall_arrayref("SELECT uri_pattern, type, options FROM map_uri WHERE app_id = ? OR app_id IS NULL ORDER BY type", undef, $app->{id});
	foreach my $row (@$plugins) {
		if((@result) = ($uri =~ /$exp/)){
		    my $module_name;
	        my $options;
	        my @result;
	        my $exp = @$row[0];
	        
			$log->debug("Pattern ".$exp." matches with URI");
			if(@$row[1] eq 'Plugin'){
				$module_name = 'Plugin::Plugin_'.uc(@$row[2]);
				$options = \@result;
			} elsif (@$row[1] eq 'Rewrite'){
				$module_name = 'Plugin::Plugin_REWRITE';
			    $log->debug(@$row[2]);
				$options = @$row[2];
			}

			$log->debug($module_name);
    
            #Calling associated plugin
			load $module_name;
			
			#Get return
			$ret = $module_name->plugin($r, $log, $dbh, $app, $options);
			
            return $ret if($ret or uc(@$row[2]) eq "STATIC")
		}
	}	

	#If application exists and is not down, check auth
	if($app and $app->{'up'}){
		my $proxy_url;
	    if ($uri =~ /^(http|https|ftp):\/\//) {
            	$proxy_url = $uri;
	    }
	    else {
		    $proxy_url = $app->{'url'}.$uri;
	    }
	    
		#No authentication is needed
    	my $auths = $app->{'auth'};
    	if(not defined @$auths or not @$auths){
    		#Destroy useless handlers
    		$r->set_handlers(PerlAuthenHandler => undef);
    		$r->set_handlers(PerlAuthzHandler => undef);
		    $log->debug("Setting pnotes 'url_to_mod_proxy' to " .$proxy_url) unless $r->pnotes('url_to_mod_proxy');
		    $r->filename("proxy:".$proxy_url);
		    $r->pnotes('url_to_mod_proxy' => $proxy_url) unless $r->pnotes('url_to_mod_proxy');

		    return Apache2::Const::OK;
    	}
    	
    	#Getting session app if exists. If not, creating one
        my ($id_app) = get_cookie($r->headers_in->{Cookie}, 'vulture_app=([^;]*)');
		my (%session_app);
		session(\%session_app, $app->{timeout}, $id_app, $log);
		$r->pnotes('id_session_app' => $id_app);
		
		# We have authorization for this app so let's go with mod_proxy
		if(defined $session_app{is_auth} and $session_app{is_auth} == 1){

			#Setting username && password for FixupHandler and ResponseHandler
			$r->pnotes('username' => $session_app{username});
			$r->pnotes('password' => $session_app{password});
			
			$log->debug("This app : ".$r->hostname." is secured or display portal is on. User has a valid cookie for this app / is logged in the SSO Portal");
			
			#Destroy useless handlers
    		$r->set_handlers(PerlAuthenHandler => undef);
    		$r->set_handlers(PerlAuthzHandler => undef);

			#Mod_proxy with apache : user will not see anything
			if(not defined $session_app{SSO_Forwarding}){
				$log->debug("Setting pnotes 'url_to_mod_proxy' to ".$proxy_url) unless $r->pnotes('url_to_mod_proxy');
				$r->filename("proxy:".$proxy_url);
				$r->pnotes('url_to_mod_proxy' => $proxy_url) unless $r->pnotes('url_to_mod_proxy');
			}
			return Apache2::Const::OK;
		
		#Not authentified in this app. Setting cookie for app. Redirecting to SSO Portal.
		}else{
			$log->debug("App ".$r->hostname." is secured and user is not authentified in app. Let's have fun with AuthenHandler / redirect to SSO Portal ".$intf->{'sso_portal'});
			$r->status(200);
			$r->err_headers_out->add('Set-Cookie' => $r->dir_config('VultureAppCookieName')."=".$session_app{_session_id}."; path=/; domain=".$r->hostname);
			
			#Fill session for SSO Portal
			$session_app{app_name} = $r->hostname;
			$session_app{url_to_redirect} = $unparsed_uri;

			#Redirect to SSO Portal if $r->pnotes('url_to_mod_proxy') is not set by Rewrite engine
            if(not $r->pnotes('url_to_mod_proxy')){
                my $intf = get_intf($log, $dbh, $r->dir_config('VultureID'));
                my $url_to_redirect = '';
                if ($intf->{'sso_portal'}){
                    $url_to_redirect = $intf->{'sso_portal'}.':'.$r->get_server_port;
                } else {
                    $url_to_redirect = $r->is_https ? 'https://' : 'http://';
                    $url_to_redirect .= $app->{name}.':'.$app->{port};

                }
                $url_to_redirect .= '/?vulture_app='.$session_app{_session_id};
			    $r->err_headers_out->set('Location' => $url_to_redirect);
			    return Apache2::Const::REDIRECT;
            } else {
                #Destroy useless handlers
        		$r->set_handlers(PerlAuthenHandler => undef);
        		$r->set_handlers(PerlAuthzHandler => undef);
                return Apache2::Const::OK;
            }
		}
	
	#SSO Portal
	} elsif ($unparsed_uri =~ /vulture_app=([^;]*)/){

		$log->debug('Entering SSO Portal mode.');
        
        #Getting previous app session
		my $app_cookie_name = $1;
		my $SSO_cookie_name = get_cookie($r->headers_in->{Cookie}, 'vulture_proxy=([^;]*)');

		my (%session_SSO);
		my (%session_app);
		session(\%session_SSO, $app->{timeout}, $SSO_cookie_name);
		
		#Get session id if not exists
		if($SSO_cookie_name ne $session_SSO{_session_id}){
			$log->debug("Replacing SSO id");
			$SSO_cookie_name = $session_SSO{_session_id};
		}

		#Get app
		session(\%session_app, $app->{timeout}, $app_cookie_name);
		my $app = get_app($log, $session_app{app_name}, $dbh, $r->dir_config('VultureID'));
		
		$r->pnotes('app' => $app);

		$r->pnotes('id_session_app' => $app_cookie_name);
		$r->pnotes('id_session_SSO' => $SSO_cookie_name);
		
		return Apache2::Const::OK;

	#Application is down or unusable
	} elsif ($app and not $app->{'up'}){
		$log->error('Trying to redirect to '.$r->hostname.' but failed because '.$r->hostname.' is down');
		$r->status(Apache2::Const::SERVER_ERROR);
		return Apache2::Const::DONE;
	
	#Fail
	} else {
		$log->error('Trying to redirect to '.$r->hostname.' but failed because '.$r->hostname.' doesn\'t exist in Database');
		$r->status(Apache2::Const::NOT_FOUND);
		return Apache2::Const::DONE;
	}
	return Apache2::Const::OK;
}

1;