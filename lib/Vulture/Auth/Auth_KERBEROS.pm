#file:Auth/Auth_KERBERPS.pm
#---------------------------------
package Auth::Auth_KERBEROS;

use Apache2::RequestRec ();
use Apache2::RequestIO ();
use Apache2::Connection ();
use Apache2::Log;
use Apache2::Reload;
use Authen::Simple::Kerberos;

use Data::Dumper;

use Apache2::Const -compile => qw(OK FORBIDDEN);

sub checkAuth{
	my ($package_name, $r, $log, $dbh, $app, $user, $password, $id_method) = @_;	

	$log->debug("########## Auth_KERBEROS ##########");

	my $query = "SELECT * FROM kerberos WHERE id='".$id_method."'";
    my $sth = $dbh->prepare($query);
    $log->debug($query);
    $sth->execute;
    my $ref = $sth->fetchrow_hashref;
    $sth->finish();

    my $realm = $ref->{'realm'};

    my $kerberos = Authen::Simple::Kerberos->new(realm => $realm );
    if ( $kerberos->authenticate( $user, $password ) ) {
 		return Apache2::Const::OK;	
    } else {
		return Apache2::Const::FORBIDDEN;
	}
}
1;
