#!/usr/bin/perl
use strict;
use warnings;
use 5.14.0;
use Test::More;
use FindBin;
use Test::More;
use lib "$FindBin::Bin/../../lib";
use English qw(-no_match_vars);

if ( !($ENV{ALL} or $ENV{POD}) ) {
    my $msg = 'Author test.  Set $ENV{POD} to a true value to run.';
    plan( skip_all => $msg );
}

eval { require Test::Pod::Coverage; };

if ( $EVAL_ERROR ) {
    my $msg = 'Test::Pod::Coverage required to test POD';
    plan( skip_all => $msg );
}

Test::Pod::Coverage->import;
plan( skip_all => "Not implemented yet" );
for my $module (all_modules( "$FindBin::Bin/../../lib/BB")) {
    pod_coverage_ok( $module );
}
done_testing
