#!/usr/bin/perl
use strict;
use warnings;
use 5.14.0;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../../lib";
use Test::Exception;

BEGIN {
    use_ok('BB::Dokuwiki');
    use_ok('BB::Common');
    &Opts::parse();
    &Opts::validate();
    &Util::connect;
}
is( &Dokuwiki::return_client, undef, "Dokuwiki Client is undefined by default" );
my $user =  &Opts::get_option('username');
my $pass =  "TestTest";
my $server = "https://supportwiki.balabit/lib/exe/xmlrpc.php";

throws_ok{ &Dokuwiki::connect( $server, $user, $pass) } 'Connection::Connect', "Connect throws exception if connection unsuccesful";
is( &Dokuwiki::return_client, undef, "Dokuwiki Client is undefined after bad connect" );
throws_ok{ &Dokuwiki::request( "RingDingding") } 'Connection::Connect', "Request throws exception if no connection is present";
$pass =  &Opts::get_option('password');
is( &Dokuwiki::connect($server, $user, $pass), 1, "Dokuwiki connection succesful" );
isnt( &Dokuwiki::return_client, undef, "Dokuwiki Client is defined after good connect" );
throws_ok{ &Dokuwiki::connect( $server, $user, $pass) } 'Connection::Connect', "Connect throws exception if already connected to server";
my $ret = &Dokuwiki::request( RPC::XML::request->new('dokuwiki.getVersion'));
like( $ret, qr/^Release/, "getVersion like expected");
$ret = &Dokuwiki::request( RPC::XML::request->new('dokuwiki.LikeABoss'));
is( $ret->{faultString}, 'Method does not exist', "Correct faultstring is returned");
done_testing;

END {
    &Util::disconnect();
}
