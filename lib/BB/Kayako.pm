package Kayako;

use strict;
use warnings;
use DBI;

=pod

=head1 Kayako.pm

Subroutines from BB/Kayako.pm

=cut

BEGIN {
    use Exporter;
    our @ISA    = qw( Exporter );
    our @EXPORT = qw( );
}

=pod

=head2 connect_kayako

=head3 PURPOSE

Connects to the local kayako Database server

=head3 PARAMETERS

=over

=back

=head3 RETURNS

A DBI handle

=head3 DESCRIPTION

=head3 THROWS

Connection::Connect if connection fails to server

=head3 COMMENTS

=head3 SEE ALSO

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

=head2 disconnect_kayako

=head3 PURPOSE

Disconnects from kayako server

=head3 PARAMETERS

=over

=item dbh

A DBI handle

=back

=head3 RETURNS

True on success

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

=head3 SEE ALSO

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

=head2 run_query

=head3 PURPOSE

Runs a requested query on DBI handle

=head3 PARAMETERS

=over

=item dbh

A DBI handle

=item query

The requested query to run

=back

=head3 RETURNS

The results of the query in a hashref

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

=head3 SEE ALSO

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
