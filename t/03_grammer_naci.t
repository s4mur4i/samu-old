#!/usr/bin/perl
use strict;
use warnings;
use 5.14.0;
use FindBin;
use English qw(-no_match_vars);
use Test::More;

if ( not $ENV{CRITIC} ) {
    my $msg = 'Author test.  Set $ENV{CRITIC} to a true value to run.';
    plan( skip_all => $msg );
}

eval { require Test::PerlTidy; };

if ( $EVAL_ERROR ) {
    my $msg = 'Test::Perl::Critic required to criticise code';
    plan( skip_all => $msg );
}
Test::PerlTidy->import();
diag("Running PerlTidy");
run_tests(
    path    => "$FindBin::Bin/../",
    debug   => 0,
    mute    => 1,
    exclude => [ qr{old/}, qr{VMware/}, qr{\.t$}, qr{\.sh$}, qr{\.pod$}, qr{PERL_MODULES$} ]
);
