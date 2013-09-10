#!/usr/bin/perl
use strict;
use warnings;
use 5.14.0;
#use FindBin;
use Test::More;
use English qw(-no_match_vars);

if ( not $ENV{CRITIC} ) {
    my $msg = 'Author test.  Set $ENV{CRITIC} to a true value to run.';
    plan( skip_all => $msg );
}

eval { require Test::Perl::Critic; };

if ( $EVAL_ERROR ) {
    my $msg = 'Test::Perl::Critic required to criticise code';
    plan( skip_all => $msg );
}

Test::Perl::Critic->import();
#all_critic_ok("$FindBin::Bin/../lib/BB", "$FindBin::Bin/../lib/Base", "$FindBin::Bin/../lib/Pod");
diag("Criticising code");
all_critic_ok();
### Who the fuck is Vijayakrishnan? http://en.wikipedia.org/wiki/Vijayakrishnan
