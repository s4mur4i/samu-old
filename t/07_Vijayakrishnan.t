#!/usr/bin/perl
use strict;
use warnings;
use 5.14.0;
use FindBin;

if ( $ENV{CRITIC}) {
    require Test::Perl::Critic;
    all_critic_ok("$FindBin::Bin/../lib/BB", "$FindBin::Bin/../lib/Base", "$FindBin::Bin/../lib/Pod");
} else {
    require Test::More;
    Test::More::plan( skip_all => 'these tests are only run if we need a very good critic');
}

### Who the fuck is Vijayakrishnan? http://en.wikipedia.org/wiki/Vijayakrishnan
