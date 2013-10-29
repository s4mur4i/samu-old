#!/usr/bin/perl
use strict;
use warnings;
use 5.14.0;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../../lib";
use Test::Exception;
use Test::Output;

BEGIN { use_ok('BB::Output'); use_ok('BB::Common'); }
is( &Output::return_csv, undef, "CSV returned undef by default");
is( &Output::return_tbh, undef, "TBH returned undef by default");
is( &Output::create_table, 1, "Table creates succesfully");
throws_ok { &Output::create_table; } 'Connection::Connect', 'Connection::Connect Exception is thrown after second create';
isa_ok( &Output::return_tbh, 'Text::Table', "TBH returned object after creation");
is( &Output::add_row( [ qw(TEST test) ]), 1,"Add row finished succesfully");
combined_like( sub{ &Output::print}, qr/^TEST\stest$/,qr/^$/, "Output of table as expected" );
is( &Output::return_tbh, undef, "TBH returned undef after print");
is( &Output::create_csv( [ qw(test test1)] ), 1, "CSV creates succesfully");
throws_ok { &Output::create_csv; } 'Connection::Connect', 'Connection::Connect Exception is thrown after second create';
isa_ok( &Output::return_csv, 'Class::CSV', "CSV returned object after creation");
is( &Output::add_row( [ qw(TEST test) ]), 1,"Add row finished succesfully");
combined_like( sub{ &Output::print}, qr/^TEST,test$/,qr/^$/, "Output of table as expected" );
is( &Output::return_csv, undef, "CSV returned undef after print");

throws_ok { &Output::add_row( [ qw(TEST test) ] ); } 'Connection::Connect', 'Exception is thrown if no defined object exists for add_row';
throws_ok { &Output::print( [ qw(TEST test) ] ); } 'Connection::Connect', 'Exception is thrown if no defined object exists for print';

#FIXME add option_parser tests
done_testing;
