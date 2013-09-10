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

eval { require Test::PureASCII; };

if ( $EVAL_ERROR ) {
    my $msg = 'Test::PureASCII required to criticise code';
    plan( skip_all => $msg );
}
Test::PureASCII->import;
diag("Files only contain ASCII chars");
all_perl_files_are_pure_ascii(
    { forbid_control => 1, forbid_tab => 1 },
    "$FindBin::Bin/..",
    "Only ASCII characters in files"
);
