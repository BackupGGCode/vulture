#file:Core/AuthzHandler.pm
#---------------------------------
#!/usr/bin/perl
package Core::AuthzHandler;
  
use strict;
use warnings;
  
use Apache2::Access ();
use Apache2::Reload;
use Apache2::RequestUtil ();
use Apache2::Log;
use Apache2::Response ();

use DBI;

use Apache2::Const -compile => qw(OK HTTP_UNAUTHORIZED);

use Core::VultureUtils qw(&session &get_memcached &notify);
use Core::ActionManager qw(&handle_action);

sub handler {
	my $r = shift;

	my $log = $r->pnotes('log');

	$log->debug("########## AuthzHandler ##########");

	#If an user was set and if he is authorized, then give him a cookie for this app
	my $user = $r->pnotes('username') || $r->user ;
	my $password = $r->pnotes('password');
	my $dbh = $r->pnotes('dbh');
	my $app = $r->pnotes('app');
	my $mc_conf = $r->pnotes('mc_conf');
    $log->error("App is missing in AuthzHandler") unless $app;
    my $intf = $r->pnotes('intf');

	#Session data
	my (%session_app);
	Core::VultureUtils::session(\%session_app, $app->{timeout}, $r->pnotes('id_session_app'), $log, $mc_conf,$app->{update_access_time});
	my (%session_SSO);
	Core::VultureUtils::session(\%session_SSO, $intf->{sso_timeout}, $r->pnotes('id_session_SSO'), $log, $mc_conf,$intf->{sso_update_access_time});

	#Bypass for Vulture Auth
	if(not $session_SSO{is_auth} and not $r->user){
		$log->debug("Bypass AuthzHandler because SSO session is not valid");
		return Apache2::Const::OK;	
	}

	#If user has valid app cookie
	if($session_app{is_auth}){
		$log->debug("User is already authorized to access this app");
		return Apache2::Const::OK;	
	}

	#Get app info coming from TransHandlerv2
	if($app and $app->{'id'}){
		
        #Get users list to notify
        my (%users);
        %users = %{Core::VultureUtils::get_memcached('vulture_users_in',$mc_conf) or {}};

		#Check if ACL is on. If not, let user go.
		if($app->{'acl'}){
			#If user was set by AuthenHandler, then check his credentials			
			if ($user){
                my $ret = Apache2::Const::HTTP_UNAUTHORIZED;
				my $module_name = "ACL::ACL_".uc($app->{'acl'}->{'acl_type'});
			
				eval {
					(my $file = $module_name) =~ s|::|/|g;
					require $file . '.pm';
					$module_name->import("checkACL");
					1;
				} or do {
					my $error = $@;
				};
				
				#Get return
				$ret = $module_name->checkACL($r, $log, $dbh, $app, $user, $app->{'acl'}->{'id_method'});
                Core::ActionManager::handle_action($r, $log, $dbh, $intf, $app, 'ACL_FAILED', 'ACL failed') if ($ret != scalar Apache2::Const::OK);
				
				#Check if User can access to the specified app
				#If yes validate the app session 
				if (defined $ret and $ret == scalar Apache2::Const::OK){
					$log->debug("User $user has credentials for this app regarding ACL. Validate app session");

                    Core::VultureUtils::notify($dbh, $app->{id}, $user, 'connection', scalar(keys %users));

					#Setting app session
					$session_app{is_auth} = 1;
					$session_app{username} = $user;
					$session_app{password} = $password;
			
					#Backward logout
					$session_app{SSO} = $r->pnotes('id_session_SSO');

					#SSO must be warned that user is logged in this app (ex : SAML)
					$session_SSO{$app->{name}} = $r->pnotes('id_session_app');

					$log->debug("Validate app session");
					return Apache2::Const::OK;
				} else {
					$log->warn("Regarding to ACL, user $user is not authorized to access to this app.");
					
                    Core::VultureUtils::notify($dbh, $app->{id}, $user, 'connection_failed', scalar(keys %users));
                    
					$session_app{is_auth} = 0;
					$r->pnotes('username' => undef);
					$r->pnotes('password' => undef);
				}
			}
			return Apache2::Const::HTTP_UNAUTHORIZED;
		} else {
			$log->debug("No ACL in this app. Validate app session for user $user");
            
            Core::VultureUtils::notify($dbh, $app->{id}, $user, 'connection', scalar(keys %users));
		
			#Setting app session
			$session_app{is_auth} = 1 ;
			$session_app{username} = $user;
			$session_app{password} = $password;

			#Backward logout
			$session_app{SSO} = $r->pnotes('id_session_SSO');

			#SSO must be warned that user is logged in this app (ex : SAML)
			$session_SSO{$app->{name}} = $r->pnotes('id_session_app');
			
			return Apache2::Const::OK;
		}
	} else {
		#CAS
		$log->debug("App is undef in AuthzHandler => CAS Mode");
		
		return Apache2::Const::OK;
	}
	return Apache2::Const::HTTP_UNAUTHORIZED;
}

1;
