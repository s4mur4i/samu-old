#!/usr/bin/perl
use strict;
use warnings;
use 5.14.0;
use Test::PerlTidy;
use FindBin;
use lib "$FindBin::Bin/../lib";

run_tests(
    path    => "$FindBin::Bin/../",
    debug   => 0,
    mute    => 1,
    exclude => [ qr{old/}, qr{VMware/}, qr{\.t$}, qr{\.sh$}, qr{\.pod$} ]
);
