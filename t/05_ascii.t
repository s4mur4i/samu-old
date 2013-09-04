#!/usr/bin/perl
use strict;
use warnings;
use 5.14.0;
use Test::More;
use Test::PureASCII;
use FindBin;
all_perl_files_are_pure_ascii(
    { forbid_control => 1, forbid_tab => 1 },
    "$FindBin::Bin/..",
    "Only ASCII characters in files"
);
done_testing;
