#!/usr/bin/perl
use strict;
use warnings;
use 5.14.0;
use FindBin;
use Test::More;
use English qw(-no_match_vars);

if ( not $ENV{AUTHOR} ) {
        my $msg = 'Author test.  Set $ENV{AUTHOR} to a true value to run.';
            plan( skip_all => $msg );
}

eval { require Test::Fixme; };

if ( $EVAL_ERROR ) {
        my $msg = 'Test::Fixme required to criticise code';
            plan( skip_all => $msg );
}

run_tests( where => "$FindBin::Bin/../" );
