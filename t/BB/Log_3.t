#!/usr/bin/perl
use strict;
use warnings;
use 5.14.0;
use Test::More;
use Test::Output;
use Module::Reload::Selective;
use FindBin;
use lib "$FindBin::Bin/../../lib";

BEGIN {
    push(@ARGV, "-vvv");
    use_ok('BB::Log');
    }
ok( &Log::verbosity eq 3, "Verbosity is at level 3");
stderr_like( sub { &Log::critical("Test") }, qr/^Log_3.t\s[^ ]*\s\[ERROR\]\s\[\d*\]:\sTest;$/ , "Critical prints correctly to stderr" );
stderr_like( sub { &Log::normal("Test") }, qr/^Log_3.t\s[^ ]*\s\[INFO\]\s\[\d*\]:\sTest;$/ , "Normal prints correctly to stderr" );
stderr_like( sub { &Log::warning("Test") }, qr/^Log_3.t\s[^ ]*\s\[WARNING\]\s\[\d*\]:\sTest;$/ , "Warning prints correctly to stderr" );
stderr_like( sub { &Log::info("Test") }, qr/^Log_3.t\s[^ ]*\s\[INFO\]\s\[\d*\]:\sTest;$/ , "Info prints correctly to stderr" );
stderr_like( sub { &Log::debug("Test") }, qr/^Log_3.t\s[^ ]*\s\[DEBUG\]\s\[\d*\]:\sTest;$/ , "Debug prints correctly to stderr" );
done_testing;
