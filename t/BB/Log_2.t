#!/usr/bin/perl
use strict;
use warnings;
use 5.14.0;
use Test::More;
use Test::Output;
use FindBin;
use lib "$FindBin::Bin/../../lib";

BEGIN {
    push(@ARGV, "-qqqq");
    use_ok('BB::Log');
}
my $level = 2;
ok( &Log::verbosity eq $level, "Verbosity is at $level");
diag("Running tests on output");
output_like( sub { &Log::debug2("Test") }, qr/^$/ ,qr/^$/ , "Debug 2 output ok on level $level" );
output_like( sub { &Log::debug1("Test") }, qr/^$/ ,qr/^$/ , "Debug 1 output ok on level $level" );
output_like( sub { &Log::debug("Test") }, qr/^$/ ,qr/^$/ , "Debug output ok on level $level" );
output_like( sub { &Log::info("Test") }, qr/^$/ ,qr/^$/ , "Info output ok on level $level" );
output_like( sub { &Log::notice("Test") }, qr/^$/ ,qr/^$/ , "Notice output ok on level $level" );
output_like( sub { &Log::warning("Test") }, qr/^$/ ,qr/^$/ , "Warning output ok on level $level" );
output_like( sub { &Log::error("Test") }, qr/^$/ ,qr/^$/ , "Error output ok on level $level" );
output_like( sub { &Log::critical("Test") }, qr/^$/ ,qr/^$/ , "Critical output ok on level $level" );
output_like( sub { &Log::alert("Test") }, qr/^$/ ,qr/^Log_${level}.t\s\[ALERT\]:\sTest;$/ , "Alert output ok on level $level" );
output_like( sub { &Log::emergency("Test") }, qr/^$/ ,qr/^Log_${level}.t\s\[EMERGENCY\]:\sTest;$/ , "Emergency output ok on level $level" );
done_testing;
