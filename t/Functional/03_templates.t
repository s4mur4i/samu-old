#!/usr/bin/perl
use strict;
use warnings;
use 5.14.0;
use Test::More;
use Test::Output;
use FindBin;
use lib "$FindBin::Bin/../../lib/";
use BB::Common;
use Base::admin;

ok( \&admin::templates, "Admin templates sub ran succesfully" );
stderr_like( \&admin::templates, qr/^admin.pm\s[^ ]*\s\[INFO\]\s\[\d*\]:\sName:'[^ ']*'\s*Path:'[^ ']*';/, "Output is a valid templates output" );
done_testing;
