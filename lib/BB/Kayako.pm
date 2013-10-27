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

my $dbh;

=pod

=head2 connect_kayako

=head3 PURPOSE

Connects to the local kayako Database server

=head3 PARAMETERS

=over

=back

=head3 RETURNS

True on success

=head3 DESCRIPTION

=head3 THROWS

Connection::Connect if connection fails to server

=head3 COMMENTS

=head3 TEST COVERAGE

Tested if exception thrown if object already exists
Also tested if connection works

=cut

sub connect_kayako {
    &Log::debug("Starting Kayako::connect_kayako sub");
    my $dsn  = "dbi:mysql:kayako:10.21.0.17";
    my $user = "vmware-infra";
    my $pass = "Di2ooChei9iohewe";
    if (!$dbh) {
        $dbh = DBI->connect( $dsn, $user, $pass, { RaiseError => 1, AutoCommit => 0 } ) or Connection::Connect->throw( error => 'Could not connect to Kayako DB', type  => 'mysl::dbi', dest  => $dsn);
    } else {
        Connection::Connect->throw( error => "Already connected to Kayako", type => "Kayako", dest => $dsn);
    }
    &Log::debug("Finishing Kayako::connect_kayako sub");
    &Log::dumpobj( "dbi handle", $dbh );
    return 1;
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

Connection::Connect if no dbh object exists

=head3 COMMENTS

=head3 TEST COVERAGE

Tested if disconnect disconnects and deletes object, also tested if exception is thrown if no object is defined

=cut

sub disconnect_kayako {
    &Log::debug("Starting Kayako::disconnect_kayako sub");
    if ( $dbh ) {
        $dbh->disconnect or &Log::warning( "Kayako db disconnect warning:" . $dbh->errstr );
        undef $dbh;
    } else {
        Connection::Connect->throw(error => "Not connected to kayako server", type => "Kayako", dest => "Kayako local server");
    }
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

Connection::Connect if no dbh object exists

=head3 COMMENTS

=head3 TEST COVERAGE

Tested if correct response is returned, also tested if exception is thrown if no dbh object exists

=cut

sub run_query {
    my ( $query ) = @_;
    &Log::debug("Starting Kayako::run_query sub");
    &Log::debug("Opts are: query=>'$query'");
    if ( !$dbh) {
        Connection::Connect->throw( error => "Not connected to kayako", type => "Kayako", dest => "Kayako local server");
    }
    my $sth = $dbh->prepare("$query");
    $sth->execute();
    my $result = $sth->fetchrow_hashref();
    &Log::dumpobj( "result", $result );
    &Log::debug("Finishing Kayako::run_query sub");
    return $result;
}

sub return_dbh {
    return $dbh;
}

1
