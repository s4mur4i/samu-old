#!/usr/bin/perl
use strict;
use warnings;
use 5.14.0;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../../lib";
use SAMU_Test::Common;

BEGIN { use_ok('Base::kayako') }
my $module = &kayako::module_opts;
&Test::traverse_opts( $module, ["KAYAKO"], "$FindBin::Bin/../../doc/main.pod" );
&Test::verify_complete( "kayako");
done_testing;
