#!/usr/bin/perl
use strict;
use warnings;
use 5.14.0;
use Test::More;
use Test::Output;
use Module::Reload::Selective;
use FindBin;
use lib "$FindBin::Bin/../../lib";

BEGIN { use_ok('BB::Log'); }
ok( &Log::verbosity eq 0, "Verbosity is at default level");
stderr_like( sub { &Log::critical("Test") }, qr/^Log_0.t\s[^ ]*\s\[ERROR\]\s\[\d*\]:\sTest;$/ , "Critical prints correctly to stderr" );
stderr_like( sub { &Log::normal("Test") }, qr/^Log_0.t\s[^ ]*\s\[INFO\]\s\[\d*\]:\sTest;$/ , "Normal prints correctly to stderr" );
stderr_like( sub { &Log::warning("Test") }, qr/^$/ , "Warning prints correctly to stderr" );
stderr_like( sub { &Log::info("Test") }, qr/^$/ , "Info prints correctly to stderr" );
stderr_like( sub { &Log::debug("Test") }, qr/^$/ , "Debug prints correctly to stderr" );
done_testing;
