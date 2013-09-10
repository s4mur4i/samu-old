#!/usr/bin/perl
use strict;
use warnings;
use 5.14.0;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../../lib";

BEGIN { use_ok('BB::Log'); }
diag("Dummy test to use BB::Log module");
done_testing;
