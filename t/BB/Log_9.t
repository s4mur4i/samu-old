#!/usr/bin/perl
use strict;
use warnings;
use 5.14.0;
use Test::More;
use Test::Output;
use FindBin;
use lib "$FindBin::Bin/../../lib";

BEGIN {
    push( @ARGV, "-vvv" );
    use_ok('BB::Log');
}
my $level = 9;
ok( &Log::verbosity eq $level, "Verbosity is at $level" );
diag("Running tests on output");
output_like( sub { &Log::debug2("Test") },
    qr/^$/, qr/^$/, "Debug 2 output ok on level $level" );
output_like(
    sub { &Log::debug1("Test") },
    qr/^$/,
    qr/^Log_${level}.t\s\[DEBUG1\]:\sTest;$/,
    "Debug 1 output ok on level $level"
);
output_like(
    sub { &Log::debug("Test") },
    qr/^$/,
    qr/^Log_${level}.t\s\[DEBUG\]:\sTest;$/,
    "Debug output ok on level $level"
);
output_like(
    sub { &Log::info("Test") },
    qr/^$/,
    qr/^Log_${level}.t\s\[INFO\]:\sTest;$/,
    "Info output ok on level $level"
);
output_like(
    sub { &Log::notice("Test") },
    qr/^$/,
    qr/^Log_${level}.t\s\[NOTICE\]:\sTest;$/,
    "Notice output ok on level $level"
);
output_like(
    sub { &Log::warning("Test") },
    qr/^$/,
    qr/^Log_${level}.t\s\[WARNING\]:\sTest;$/,
    "Warning output ok on level $level"
);
output_like(
    sub { &Log::error("Test") },
    qr/^$/,
    qr/^Log_${level}.t\s\[ERROR\]:\sTest;$/,
    "Error output ok on level $level"
);
output_like(
    sub { &Log::critical("Test") },
    qr/^$/,
    qr/^Log_${level}.t\s\[CRITICAL\]:\sTest;$/,
    "Critical output ok on level $level"
);
output_like(
    sub { &Log::alert("Test") },
    qr/^$/,
    qr/^Log_${level}.t\s\[ALERT\]:\sTest;$/,
    "Alert output ok on level $level"
);
output_like(
    sub { &Log::emergency("Test") },
    qr/^$/,
    qr/^Log_${level}.t\s\[EMERGENCY\]:\sTest;$/,
    "Emergency output ok on level $level"
);
done_testing;
