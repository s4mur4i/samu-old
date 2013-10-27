#!/usr/bin/perl
use strict;
use warnings;
use 5.14.0;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../../lib";
use Test::Exception;

BEGIN { use_ok('BB::Kayako'); use_ok('BB::Common'); }
is( &Kayako::return_dbh, undef, "Kayako dbh is undefined by default" );
is(&Kayako::connect_kayako, 1, "Connect kayako returns success");
throws_ok{ &Kayako::connect_kayako( ) } 'Connection::Connect', "Exception is thrown if second connection is requested";
isa_ok( &Kayako::return_dbh, 'DBI::db', "DBH is correct object" );
my $result = &Kayako::run_query( "select ticketstatustitle from swtickets where ticketid = '1'" );
is( $result->{ticketstatustitle}, 'Closed-Resolved', "Query ran succesfully on box" );
is( &Kayako::disconnect_kayako(), 1, "Disconnet successful from kayako db server" );
is( &Kayako::return_dbh, undef, "Kayako dbh is undefined after disconnect" );
throws_ok{ &Kayako::disconnect_kayako( ) } 'Connection::Connect', "Exception is thrown if Disconnect is requested if no connection exists";
throws_ok{ &Kayako::run_query( "test" ) } 'Connection::Connect', "Exception is thrown if if query requested without dbh object";
done_testing;
