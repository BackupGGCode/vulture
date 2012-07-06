#file:SSO/SSO_FORWARD.pm
#-------------------------
#!/usr/bin/perl
package SSO::SSO_FORWARD;

use strict;
use warnings;

BEGIN {
    use Exporter ();
    our @ISA = qw(Exporter);
    our @EXPORT_OK = qw(&forward);
}

use Apache2::RequestRec ();
use Apache2::RequestIO ();
use Apache2::Connection ();

use Apache2::Log;
use Apache2::Reload;

use LWP::UserAgent;
use WWW::Mechanize;
use WWW::Mechanize::GZip;
use HTTP::Request;
use HTML::Form;

use Apache2::Const -compile => qw(OK REDIRECT);

use Core::VultureUtils qw(&session);
use SSO::ProfileManager qw(&get_profile &delete_profile);

use Apache::SSLLookup;
use MIME::Base64;

use APR::URI;
use APR::Table;
use APR::SockAddr;

use Data::Dumper;

use URI::Escape;

sub rewrite_uri { # Rewrite uri for being valid
   my ($r, $app, $uri, $real_post_url, $log) = @_;

	if ($uri !~ /^(http|https):\/\/(.*)/ ) {
		my $rewrite_uri2 = APR::URI->parse($r->pool, $real_post_url);
		my $path = $rewrite_uri2->path();
		if ($uri =~ /^\/(.*)/) {
			$rewrite_uri2->hostname($app->{'name'});
			$rewrite_uri2->path($uri);
		}
		else {
			$path =~ s/[^\/]+$/$uri/g;
			$rewrite_uri2->path($path);	
		}
	$uri = $rewrite_uri2->unparse;
   }
   my $rewrite_uri = APR::URI->parse($r->pool, $uri);
   $rewrite_uri->hostname($app->{'name'});
   $rewrite_uri->scheme('http');
   $rewrite_uri->scheme('https') if $r->is_https;
   $rewrite_uri->port($r->connection->local_addr->port);
   return $rewrite_uri->unparse;
} 

sub handle_action{
    my ($r, $log, $dbh, $app, $response, $user) = @_;
    
    my($query, $type, $options);
    $query = 'SELECT is_in_url, is_in_url_action, is_in_url_options, is_in_page, is_in_page_action, is_in_page_options FROM sso, app WHERE app.id = ? AND sso.id = app.sso_forward_id';
    my $sth = $dbh->prepare($query);
	$sth->execute($app->{id});
	my ($is_in_url, $is_in_url_action, $is_in_url_options, $is_in_page, $is_in_page_action, $is_in_page_options) = $sth->fetchrow;
    $sth->finish();
    
    #Check if action is needed (grep in url, grep in page or by return code)
    if ($is_in_url and $r->unparsed_uri =~ /$is_in_url/){
        $type = $is_in_url_action;
        $options = $is_in_url_options;
    } elsif ($is_in_page and $response->as_string =~ /$is_in_page/){
        $type = $is_in_page_action;
        $options = $is_in_page_options;
        
    # Headers
    } else{
        # 10x headers
        if ($response->is_info){
            #$query = 'SELECT is_info, is_info_options FROM sso, app WHERE app.id = ? AND sso.id = app.sso_forward_id';
	    $query = 'SELECT is_info, is_info_options FROM sso JOIN app ON sso.id = app.sso_forward_id WHERE app.id = ?';
        # 20x headers
        } elsif ($response->is_success){
            #$query = 'SELECT is_success, is_success_options FROM sso, app WHERE app.id = ? AND sso.id = app.sso_forward_id';
	    $query = 'SELECT is_success, is_success_options FROM sso JOIN app ON sso.id = app.sso_forward_id WHERE app.id = ?';

        # 30x headers
        } elsif ($response->is_redirect) { 
            #$query = 'SELECT is_redirect, is_redirect_options FROM sso, app WHERE app.id = ? AND sso.id = app.sso_forward_id';
	    $query = 'SELECT is_redirect, is_redirect_options FROM sso JOIN app ON sso.id = app.sso_forward_id WHERE app.id = ?';
        
        # 40x and 50x headers
        } elsif ($response->is_error) {
            #$query = 'SELECT is_error, is_error_options FROM sso, app WHERE app.id = ? AND sso.id = app.sso_forward_id';
	    $query = 'SELECT is_error, is_error_options FROM sso JOIN app ON sso.id = app.sso_forward_id WHERE app.id = ?';
        # No action defined
        }
        
        $log->debug($query);

        $sth = $dbh->prepare($query);
        $sth->execute($app->{id});
        ($type, $options) = $sth->fetchrow;
        $sth->finish();
    }
    
    #Trigger action to do
	if($type){
        $log->debug($type.' => '.$options);
        if($type eq 'message'){
            $r->content_type('text/html');
            if($options){
                $r->print($options);
            } else {
                $r->print($response->as_string);
            }
            return Apache2::Const::OK;
        } elsif($type eq 'log'){
            $log->debug('Response from app : '.$response->as_string);
        } elsif($type eq 'redirect'){
            $r->headers_out->set('Location' => $options);
            $r->status(302);
            return Apache2::Const::REDIRECT;
        } elsif($type eq 'relearning') {
			SSO::ProfileManager::delete_profile($r, $log, $dbh, $app, $user);
			$log->debug('Pattern detected, deleting profile and relearning credentials');
			$r->pnotes('SSO_Forwarding' => 'LEARNING');
			$r->headers_out->add('Location' => $r->unparsed_uri);	

			#Set status
			$r->status(302);
			return Apache2::Const::REDIRECT;
		}
    }
    
    #If no action defined, redirect client to Location header (if defined) or to the /
    my $redirect = $r->unparsed_uri;
    if ($response->headers->header('Location')){
        $redirect = SSO::SSO_FORWARD::rewrite_uri($r,$app,$response->headers->header('Location'),$app->{url}.$app->{logon_url},$log);
        $log->debug("Changing redirect to $redirect");
    }
    
    $log->debug("Ending SSO Forward");
    $r->pnotes('SSO_Forwarding' => undef);
    $r->headers_out->add('Location' =>  $redirect );
    $r->status(302);
    return Apache2::Const::REDIRECT;
}

sub forward{
	my ($package_name, $r, $log, $dbh, $app, $user, $password) = @_;

    $r = Apache::SSLLookup->new($r);

	my (%session_app);
	Core::VultureUtils::session(\%session_app, undef, $r->pnotes('id_session_app'), $log, $app->{update_access_time});

    my %headers_vars = (
		    2 => 'SSL_CLIENT_I_DN',
		    3 => 'SSL_CLIENT_M_SERIAL',
		    4 => 'SSL_CLIENT_S_DN',
		    5 => 'SSL_CLIENT_V_START',
		    6 => 'SSL_CLIENT_V_END',
		    7 => 'SSL_CLIENT_S_DN_C',
		    8 => 'SSL_CLIENT_S_DN_ST',
		    9 => 'SSL_CLIENT_S_DN_Email',
		    10 => 'SSL_CLIENT_S_DN_L',
		    11 => 'SSL_CLIENT_S_DN_O',
		    12 => 'SSL_CLIENT_S_DN_OU',
		    13 => 'SSL_CLIENT_S_DN_CN',
		    14 => 'SSL_CLIENT_S_DN_T',
		    15 => 'SSL_CLIENT_S_DN_I',
		    16 => 'SSL_CLIENT_S_DN_G',
		    17 => 'SSL_CLIENT_S_DN_S',
		    18 => 'SSL_CLIENT_S_DN_D',
		    19 => 'SSL_CLIENT_S_DN_UID',
		   );

	$log->debug("########## SSO_FORWARD ##########");

	$log->debug("LWP::UserAgent is emulating post request on ".$app->{name});

	#Getting SSO type
	my $sso_forward_type = $app->{'sso'}->{'type'};
    my $sso_follow_get_redirect = $app->{'sso'}->{'follow_get_redirect'};
	$log->debug("SSO_FORWARD_TYPE=".$sso_forward_type);

	#Setting browser
	my ($mech, $response, $post_response, $request, $cookies);
    $mech = WWW::Mechanize::GZip->new;

	$mech->cookie_jar( {} );
    
    $mech->delete_header('Host');
    $mech->add_header('Host' => $r->headers_in->{'Host'});

	#Setting proxy if needed
	if ($app->{remote_proxy} ne ''){
		$mech->proxy(['http', 'https'], $app->{remote_proxy});
	}
    
    #Just send request with Authorization
    if($sso_forward_type eq 'sso_forward_htaccess'){
        $request = HTTP::Request->new(GET => $app->{url}.$app->{logon_url});

        $request->push_header('Referer' => '-');

        #Sending Authorization header if needed by SSO forward type
        $request->push_header('Authorization' => "Basic " . encode_base64($user.':'.$password));
    
    #Get form first then POST infos
    } else {
        #Push user-agent, etc.
        my $url = URI->new($app->{url}.$app->{logon_url});
        $request = HTTP::Request->new(GET => $url);
        $request->remove_header('User-Agent');
        $request->push_header('User-Agent' => $r->headers_in->{'User-Agent'});
        $mech->delete_header('User-Agent');
        $mech->add_header('User-Agent' => $r->headers_in->{'User-Agent'});
		my $sth = $dbh->prepare("SELECT name, type, value FROM header WHERE app_id= ?");
		$sth->execute($app->{id});
		while (my ($name, $type, $value) = $sth->fetchrow) {
			if ($type eq "REMOTE_ADDR"){
				$value = $r->connection->remote_ip;
			#Nothing to do
			} elsif ($type eq "CUSTOM"){
			#Types related to SSL
			} else {
				$value = $r->ssl_lookup($headers_vars{$type}) if (exists $headers_vars{$type});
			}
			
			#Try to push custom headers
			eval {
			    $request->remove_header($name);
                $request->push_header($name => $value);
			    $mech->delete_header($name);
                $mech->add_header($name => $value);
				$log->debug("Pushing custom header $name => $value");
			};
		}
		$sth->finish();

        #Get the form page if no redirect follow
        
        if (int($sso_follow_get_redirect) != 1){
			$mech->max_redirect(0);
        }
		$mech->add_header('Host' => $r->headers_in->{'Host'});
        $response = $mech->get($app->{url}.$app->{logon_url});

        $log->debug($response->request->as_string);
        $log->debug($response->as_string);

        #Get profile
        my %results = %{SSO::ProfileManager::get_profile($r, $log, $dbh, $app, $user)};

        #Get form which contains fields set in admin
		while (my ($key, $value) = each(%results)){
			$log->debug($key);
			if ($key eq "cookie") {
				$cookies = $value;
				delete($results{$key});
			}
		}

        my $form = $mech->form_with_fields(keys %results) if %results;

        #Fill form with profile
        if ($form and %results){
            while (my ($key, $value) = each(%results)){
                $mech->field($key, $value);
            }
            
            #Simulate click
            $request = $form->click();
        }
    }
    $log->debug($cookies);
    #Setting headers for both htaccess and normal way
    #Push user-agent, etc.
	$request->push_header('User-Agent' => $r->headers_in->{'User-Agent'});

    #Host header
    $request->push_header('Host' => $r->headers_in->{'Host'});
	
    if (defined($r->headers_in->{'Max-Forwards'})) {
        $request->push_header('Max-Forwards' => $r->headers_in->{'Max-Forwards'} - 1);
    } else {
        $request->push_header('Max-Forwards' => '10');
    }
    if (defined($r->headers_in->{'X-Forwarded-For'})) {
        $request->push_header('X-Forwarded-For' => $r->headers_in->{'X-Forwarded-For'}.", ".$r->connection->remote_ip);
    } else {
        $request->push_header('X-Forwarded-For' => $r->connection->remote_ip);
    }

    $request->push_header('X-Forwarded-Host' => $r->hostname());
    $request->push_header('X-Forwarded-Server' => $r->hostname());
    
    #Accept* headers
    $request->push_header('Accept' => $r->headers_in->{'Accept'});
    $request->push_header('Accept-Language' => $r->headers_in->{'Accept-Language'});
    $request->push_header('Accept-Encoding' => $r->headers_in->{'Accept-Encoding'});
    $request->push_header('Accept-Charset' => $r->headers_in->{'Accept-Charset'});
    
    #We need to parse referer to replace @ IP by hostnames
    my $host = $r->headers_in->{'Host'};
    my $parsed_uri = APR::URI->parse($r->pool, $app->{url}.$app->{logon_url});
    $parsed_uri->scheme('http');
    $parsed_uri->scheme('https') if $r->is_https;
    $parsed_uri->port($r->get_server_port());
    $parsed_uri->hostname($host);
    $request->push_header('Referer' => $parsed_uri->unparse);

    #Getting custom headers defined in admin
    my $sth = $dbh->prepare("SELECT name, type, value FROM header WHERE app_id = ?");
    $sth->execute($app->{id});
    while (my ($name, $type, $value) = $sth->fetchrow) {
        if ($type eq "REMOTE_ADDR"){
	        $value = $r->connection->remote_ip;
        } elsif ($type eq "CUSTOM"){
        } else {
            $value = $r->ssl_lookup($headers_vars{$type}) if (exists $headers_vars{$type});
        }
        
        #Try to push custom headers
        eval {
            $request->remove_header($name);
            $request->push_header($name => $value);
            $log->debug("Pushing custom header $name => $value");
        };
	}
    $sth->finish();

    foreach (split("\n", $mech->cookie_jar->as_string)) {
        if (/([^,; ]+)=([^,; ]+)/) {
            $cookies .= $1."=".$2.";";
            $log->debug("ADD/REPLACE ".$1."=".$2);
        }
    }
	$request->push_header('Cookie' => $cookies); 		# adding/replace
    
    #$log->debug($request->as_string);
    
    #Send !!! simple !!! request (POST or GET (htaccess))
    #The client browser must do the rest
    #This is done after the handler action function
    $post_response = $mech->request($request);

	#Cookie coming from response and from POST response
    our %cookies_app;
    $log->debug($mech->cookie_jar->as_string);
	$mech->cookie_jar->scan( \&SSO::SSO_FORWARD::callback );


    #Keep cookies to be able to log out
    #$session_app{cookie} = join('; ', map { "'$_'=\"${cookies_app{$_}}\"" } keys %cookies_app), "\n";

    #Pre-send cookies to client after parsing
	foreach my $k (keys %cookies_app){
		$r->err_headers_out->add('Set-Cookie' => $k."=".$cookies_app{$k}."; domain=".$r->hostname."; path=/");  # Send cookies to browser's client
		$log->debug("PROPAG ".$k."=".$cookies_app{$k});
	}
    
    #Handle action needed
    return SSO::SSO_FORWARD::handle_action($r, $log, $dbh, $app, $post_response, $user);
}
sub callback {
  my($version, $key, $val, $path, $domain, $port, $path_spec, $secure, $expire, $discard, $hash) = @_;
  use vars qw(%cookies_app);
  $cookies_app{$key} = $val;
}
1;