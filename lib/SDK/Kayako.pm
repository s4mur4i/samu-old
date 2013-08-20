package Kayako;

use strict;
use warnings;
use Data::Dumper;
use DBI;
use SDK::Error;

BEGIN {
        use Exporter;
        our @ISA = qw( Exporter );
        our @EXPORT = qw( &test &connect_kayako &disconnect_kayako &run_query );
}

sub connect_kayako {
	Util::trace( 4, "Starting Kayako::connect_kayako sub\n" );
	my $dsn = "dbi:mysql:kayako:10.21.0.17";
	my $user = "vmware-infra";
	my $pass = "Di2ooChei9iohewe";
	my $dbh = DBI->connect( $dsn, $user, $pass, { RaiseError => 1, AutoCommit => 0 } ) or SDK::Error::DBI::Connect->throw( error => 'Could not connect to Kayako DB', worker => 'kayako-connect');
	Util::trace( 4, "Finished Kayako::connect_kayako sub\n" );
	return $dbh;
}

sub disconnect_kayako($) {
	my ( $dbh ) = @_;
	Util::trace( 4, "Starting Kayako::disconnect_kayako sub\n" );
	$dbh->disconnect or warn $dbh->errstr;
	Util::trace( 4, "Finished Kayako::disconnect_kayako sub\n" );
}

sub run_query($$) {
	my ( $dbh, $query ) = @_;
	Util::trace( 4, "Starting Kayako::run_query sub, query=>'$query'\n" );
	my $sth = $dbh->prepare("$query");
	$sth->execute();
	my $result = $sth->fetchrow_hashref();
	Util::trace( 4, "Finished Kayako::run_query sub\n" );
	return $result;
}

sub test() {
	Util::trace( 4, "Starting Kayako::test sub\n" );
        Util::trace( 0, "Kayako module test sub\n" );
	Util::trace( 4, "Finished Kayako::test sub\n" );
}

#### We need to end with success
1
