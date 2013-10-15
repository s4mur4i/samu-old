package Dokuwiki;

use strict;
use warnings;
use RPC::XML::Client;

=pod

=head1 Dokuwiki.pm

Subroutines from Dokuwiki.pm

=cut

BEGIN {
    use Exporter;
    our @ISA    = qw( Exporter );
    our @EXPORT = qw( );
}

my $client;

=pod

=head1 connect

=head2 PURPOSE

Connects to support dokuwiki server

=head2 PARAMETERS

=over

=item server

XMLRPC www path

=item dokuuser

User on dokuwiki

=item dokupass

Password on dokuwiki

=back

=head2 RETURNS

True on success

=head2 DESCRIPTION

=head2 THROWS

Connection::Connect if connection is unsuccesful

=head2 COMMENTS

=head2 SEE ALSO

=cut

sub connect {
    my ( $server, $dokuuser, $dokupass ) = @_;
    &Log::debug("Starting Dokuwiki::connect sub");
    &Log::debug1("Opts are: server=>'$server', dokuuser=>'$dokuuser', dokupass=>'$dokupass'");
    if ( !$client) {
        $client = RPC::XML::Client->new( $server, useragent =>[ cookie_jar => { file => "$ENV{HOME}/.cookies.txt" }],);
        my $logged_on_ok = $client->send_request('dokuwiki.login', $dokuuser, $dokupass);
        if ( $logged_on_ok->value ) {
            &Log::debug("Dokuwiki Login succesful");
        } else {
            Connection::Connect->throw( error => 'Server/Username/Password error', type => 'Dokuwiki', dest => $server );
        }
    } else {
        Connection::Connect->throw( error => 'Already connected to Dokuwiki', type => 'Dokuwiki', dest => $server );
    }
    &Log::debug("Finishing Dokuwiki::connect sub");
    return 1;
}

=pod

=head1 request

=head2 PURPOSE

Sends a request to the Dokuwiki Server

=head2 PARAMETERS

=over

=item req

A RPC::XML::CLient object with request embeded

=back

=head2 RETURNS

The result of the request

=head2 DESCRIPTION

=head2 THROWS

Connection::Connect if there is no valid connection to the server

=head2 COMMENTS

=head2 SEE ALSO

=cut

sub request {
    my ( $req ) = @_;
    &Log::debug("Starting Dokuwiki::request sub");
    &Log::dumpobj("request", $req);
    my $res;
    if ( $client ) {
        &Log::debug("We have a connection to Dokuwiki");
        $res = $client->send_request($req);
        &Log::dumpobj("return", $res);
    } else {
        Connection::Connect->throw( error => 'No Connection to Dokuwiki server', type => 'Dokuwiki', dest => 'none');
    }
    &Log::debug("Finishing Dokuwiki::request sub");
    return $res->value;
}

1
