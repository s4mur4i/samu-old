#!/usr/bin/perl
use strict;
use warnings;
use 5.14.0;
use Test::More;
use Test::Output;
use FindBin;
use lib "$FindBin::Bin/../../lib/";
use lib "$FindBin::Bin/../../lib2/";
use VMware::VIRuntime;
use BB::Common;
use Base::admin;

&Opts::parse();
&Opts::validate();
&Util::connect();

ok( \&admin::test, "Admin test sub ran succesfully" );
stderr_like( \&admin::test, qr/^admin.pm\s[^ ]*\s\[INFO\]\s\[\d*\]:\sServer\sTime\s:\s\d{4}(-\d{2}){2}T\d{2}(:\d{2}){2}\.\d+Z;/, "Output is a valid server time" );
&Util::disconnect();
done_testing;
