package Kayako;

use strict;
use warnings;
use DBI;

BEGIN {
    use Exporter;
    our @ISA    = qw( Exporter );
    our @EXPORT = qw( );
}

#tested
sub connect_kayako {
    &Log::debug("Starting Kayako::connect_kayako sub");
    my $dsn  = "dbi:mysql:kayako:10.21.0.17";
    my $user = "vmware-infra";
    my $pass = "Di2ooChei9iohewe";
    my $dbh =
      DBI->connect( $dsn, $user, $pass, { RaiseError => 1, AutoCommit => 0 } )
      or Connection::Connect->throw(
        error => 'Could not connect to Kayako DB',
        type  => 'mysl::dbi',
        dest  => $dsn
      );
    &Log::debug("Finished Kayako::connect_kayako sub");
    return $dbh;
}

#tested
sub disconnect_kayako {
    my ($dbh) = @_;
    &Log::debug("Starting Kayako::disconnect_kayako sub");
    $dbh->disconnect
      or &Log::warning( "Kayako db disconnect warning:" . $dbh->errstr );
    &Log::debug("Finished Kayako::disconnect_kayako sub");
    return 1;
}

#tested
sub run_query {
    my ( $dbh, $query ) = @_;
    &Log::debug("Starting Kayako::run_query sub, query=>'$query'");
    my $sth = $dbh->prepare("$query");
    $sth->execute();
    my $result = $sth->fetchrow_hashref();
    &Log::debug("Finished Kayako::run_query sub");
    return $result;
}

#### We need to end with success
1
