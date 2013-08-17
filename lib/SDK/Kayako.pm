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
	my $dsn = "dbi:mysql:kayako:10.21.0.17";
	my $user = "vmware-infra";
	my $pass = "Di2ooChei9iohewe";
	my $dbh = DBI->connect( $dsn, $user, $pass, { RaiseError => 1, AutoCommit => 0 } ) or return "ERROR";
	if ( !defined( $dbh ) ) {
		SDK::Error::DBI::Connect->( error => 'Could not connect to Kayako DB', worker => 'kayako-connect');
	}
	return $dbh;
}

sub disconnect_kayako($) {
	my ( $dbh ) = @_;
	$dbh->disconnect or warn $dbh->errstr;
}

sub run_query($$) {
	my ( $dbh, $query ) = @_;
	my $sth = $dbh->prepare("$query");
	$sth->execute();
	my $result = $sth->fetchrow_hashref();
	return $result;
}

sub test() {
        print "Kayako module test sub\n";
}

#### We need to end with success
1
