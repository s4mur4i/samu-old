#!/usr/bin/perl
use strict;
use warnings;
use 5.14.0;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../../lib";

BEGIN { use_ok('BB::Kayako'); }
diag("Dummy test to use BB::Kayako module");
done_testing;
