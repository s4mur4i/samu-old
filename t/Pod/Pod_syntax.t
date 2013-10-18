#!/usr/bin/perl
use strict;
use warnings;
use 5.14.0;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../../lib";
use Test::Pod;
use English qw(-no_match_vars);

if ( !( $ENV{ALL} or $ENV{POD} ) ) {
    my $msg = 'Author test.  Set $ENV{POD} to a true value to run.';
    plan( skip_all => $msg );
}

eval { require Test::Pod; };

if ($EVAL_ERROR) {
    my $msg = 'Test::Pod required to test POD';
    plan( skip_all => $msg );
}

Test::Pod->import;

all_pod_files_ok();
done_testing;
