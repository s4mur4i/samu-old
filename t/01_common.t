#!/usr/bin/perl
use strict;
use warnings;
use 5.14.0;
use Test::EOL;
use FindBin;

all_perl_files_ok( { all_reasons => 1, trailing_whitespace => 1 },
    "$FindBin::Bin/../lib/BB" );
all_perl_files_ok( { all_reasons => 1, trailing_whitespace => 1 },
    "$FindBin::Bin/../lib/Base" );
all_perl_files_ok( { all_reasons => 1, trailing_whitespace => 1 },
    "$FindBin::Bin/../lib/Pod" );
all_perl_files_ok( { all_reasons => 1, trailing_whitespace => 1 },
    "$FindBin::Bin/../doc" );
all_perl_files_ok( { all_reasons => 1, trailing_whitespace => 1 },
    "$FindBin::Bin" );
eol_unix_ok(
    "$FindBin::Bin/../samu.pl",
    'Herring is ^M and trailing whitespace free',
    { all_reasons => 1, trailing_whitespace => 1 }
);
eol_unix_ok(
    "$FindBin::Bin/../generate_perl_modules.sh",
    'generate_perl_modules is ^M and trailing whitespace free',
    { all_reasons => 1, trailing_whitespace => 1 }
);
eol_unix_ok(
    "$FindBin::Bin/../TEST_PERL_MODULES.pl",
    'TEST_PERL_MODULES is ^M and trailing whitespace free',
    { all_reasons => 1, trailing_whitespace => 1 }
);
