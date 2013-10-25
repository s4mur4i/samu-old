#!/usr/bin/perl
use strict;
use warnings;
use 5.14.0;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../../lib";
use SAMU_Test::Common;

BEGIN { use_ok('Base::network'); }
my $module = &network::module_opts;
&Test::traverse_opts( $module, ["NETWORK"], "$FindBin::Bin/../../doc/main.pod" );
&Test::verify_complete( "network");
done_testing;
