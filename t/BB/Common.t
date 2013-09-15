#!/usr/bin/perl
use strict;
use warnings;
use 5.14.0;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../../lib";

BEGIN { use_ok('BB::Common'); }
diag("Testing if use works");
like( $Common::VERSION, qr/(\d+\.){2}\d+/, "Version is a valid number" );
done_testing;
