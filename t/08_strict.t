#!/usr/bin/perl
use strict;
use warnings;
use 5.14.0;
use FindBin;
use Test::More;
use lib "$FindBin::Bin/../lib";
use English qw(-no_match_vars);

if ( !($ENV{ALL} or $ENV{AUTHOR}) ) {
    my $msg = 'Author test.  Set $ENV{AUTHOR} to a true value to run.';
    plan( skip_all => $msg );
}

eval { require Test::Strict; };

if ( $EVAL_ERROR ) {
    my $msg = 'Test::Strict required to test Strict';
    plan( skip_all => $msg );
}

my @dirs = ( "$FindBin::Bin/../blib" );
Test::Strict->import;
diag("Testing presence of strict in perl files");
all_perl_files_ok(@dirs);
