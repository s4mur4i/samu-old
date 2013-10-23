#!/usr/bin/perl
use strict;
use warnings;
use 5.14.0;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../../lib";
use SAMU_Test::Common;

BEGIN { use_ok('Base::admin'); }

my $module = &admin::module_opts;
&Test::traverse_opts( $module, ["ADMIN"], "$FindBin::Bin/../../doc/main.pod" );
&Test::parse_pod("$FindBin::Bin/../../doc/main.pod");
done_testing;
