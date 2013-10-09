package Kayako;

use strict;
use warnings;
use DBI;

BEGIN {
    use Exporter;
    our @ISA    = qw( Exporter );
    our @EXPORT = qw( );
}

=pod

=head1 connect_kayako

=head2 PURPOSE

Connects to the local kayako Database server

=head2 PARAMETERS

=over

=back

=head2 RETURNS

A DBI handle

=head2 DESCRIPTION

=head2 THROWS

Connection::Connect if connection fails to server

=head2 COMMENTS

=head2 SEE ALSO

=cut

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
    &Log::debug("Finishing Kayako::connect_kayako sub");
    &Log::dumpobj("dbi handle", $dbh);
    return $dbh;
}

=pod

=head1 disconnect_kayako

=head2 PURPOSE

Disconnects from kayako server

=head2 PARAMETERS

=over

=item dbh

A DBI handle

=back

=head2 RETURNS

True on success

=head2 DESCRIPTION

=head2 THROWS

=head2 COMMENTS

=head2 SEE ALSO

=cut

sub disconnect_kayako {
    my ($dbh) = @_;
    &Log::debug("Starting Kayako::disconnect_kayako sub");
    &Log::dumpobj("dbh", $dbh);
    $dbh->disconnect
      or &Log::warning( "Kayako db disconnect warning:" . $dbh->errstr );
    &Log::debug("Finishing Kayako::disconnect_kayako sub");
    return 1;
}

=pod

=head1 run_query

=head2 PURPOSE

Runs a requested query on DBI handle

=head2 PARAMETERS

=over

=item dbh

A DBI handle

=item query

The requested query to run

=back

=head2 RETURNS

The results of the query in a hashref

=head2 DESCRIPTION

=head2 THROWS

=head2 COMMENTS

=head2 SEE ALSO

=cut

sub run_query {
    my ( $dbh, $query ) = @_;
    &Log::debug("Starting Kayako::run_query sub");
    &Log::debug("Opts are: query=>'$query'");
    &Log::dumpobj("dbh", $dbh);
    my $sth = $dbh->prepare("$query");
    $sth->execute();
    my $result = $sth->fetchrow_hashref();
    &Log::dumpobj("result", $result);
    &Log::debug("Finishing Kayako::run_query sub");
    return $result;
}

1
