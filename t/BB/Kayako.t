#!/usr/bin/perl
use strict;
use warnings;
use 5.14.0;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../../lib";

BEGIN { use_ok('BB::Kayako'); use_ok('BB::Common'); }
my $dbh = &Kayako::connect_kayako;
isa_ok( $dbh, 'DBI::db', "Connect kayako returned correct dbh" );
my $result = &Kayako::run_query( $dbh, "select ticketstatustitle from swtickets where ticketid = '1'");
is( $result->{ticketstatustitle}, 'Closed-Resolved', "Query ran succesfully on box" );
is( &Kayako::disconnect_kayako($dbh), 1,"Disconnet successful from kayako db server" );
done_testing;
