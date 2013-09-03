use strict;
use warnings;
use 5.14.0;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../../lib";
use Test::Pod::Spelling::CommonMistakes;

BEGIN{ use_ok('Pod::Simple::Wiki::Dokuwiki'); }

ok( -e "$FindBin::Bin/../../doc/main.pod", "Main.pod exists");
pod_file_ok( "$FindBin::Bin/../../doc/main.pod" );
done_testing;
