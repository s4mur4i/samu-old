#!/usr/bin/perl
use strict;
use warnings;
use 5.14.0;
use Test::More;
use Test::Output;
use FindBin;
use lib "$FindBin::Bin/../../lib";

BEGIN { use_ok('BB::Log'); }
diag("Test sub for use of module");
output_like( sub { &Log::log2line("TEST", "TEST1") }, qr/^$/, qr/^Output.pm\s\[TEST\]:\sTEST1;$/, "log2line output is e at log level 6, nothingxpected");
output_like( sub { &Log::dumpobj("TEST", "TEST1") }, qr/^$/, qr/^$/, "dumpobj output is expected at log level 6, nothing");
done_testing;
