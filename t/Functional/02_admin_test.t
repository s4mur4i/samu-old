#!/usr/bin/perl
use strict;
use warnings;
use 5.14.0;
use Test::More;
use Test::Output;
use FindBin;
use lib "$FindBin::Bin/../../lib/";
use lib "$FindBin::Bin/../../vmware_lib/";
use VMware::VIRuntime;
use BB::Common;
use Base::admin;

BEGIN {
    &Opts::parse();
    &Opts::validate();
    &Util::connect();
}
ok( &admin::test, "Admin test sub ran succesfully" );
output_like( \&admin::test, qr/^Server\sTime\s:\s\d{4}(-\d{2}){2}T\d{2}(:\d{2}){2}\.\d+Z$/, qr/^$/, "Output is a valid server time" );
done_testing;
END {
    &Util::disconnect();
}
