#!/usr/bin/perl
use strict;
use warnings;
use 5.14.0;
use Test::EOL;
use FindBin;
use lib "$FindBin::Bin/../lib";
use SAMU_Test::Common;
my $lib = "$FindBin::Bin/../lib";

for my $module ( @{ &Test::module_namespace} ) {
    all_perl_files_ok( { all_reasons => 1, trailing_whitespace => 1 }, "$lib/$module" );
}
all_perl_files_ok( { all_reasons => 1, trailing_whitespace => 1 }, "$FindBin::Bin/../doc" );
all_perl_files_ok( { all_reasons => 1, trailing_whitespace => 1 }, "$FindBin::Bin" );
eol_unix_ok( "$FindBin::Bin/../samu.pl", 'Herring is ^M and trailing whitespace free', { all_reasons => 1, trailing_whitespace => 1 });
