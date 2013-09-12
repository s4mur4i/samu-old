#!/usr/bin/perl

use strict;
use warnings;
use 5.14.0;
use Test::More;
use English qw(-no_match_vars);

if ( not $ENV{ALL} or not $ENV{DNS} ) {
    my $msg = 'Author test.  Set $ENV{DNS} to a true value to run.';
    plan( skip_all => $msg );
}

eval { require Test::DNS; };

if ( $EVAL_ERROR ) {
    my $msg = 'Test::DNS required to test DNS';
    plan( skip_all => $msg );
}

my $dns_core    = Test::DNS->new( nameservers => ['10.10.0.1'] );
my $dns_support = Test::DNS->new( nameservers => ['10.10.0.1'] );
diag("Testing A records");
$dns_support->is_a(
    'support.balabit' => '10.21.0.23',
    'Support can resolve itself'
);
$dns_core->is_a(
    'support.balabit' => '10.21.0.23',
    'Support can be resolved by core'
);
diag("Testing NS records");
$dns_core->is_ns(
    'support.balabit' => [ 'dc-dev.support.balabit', 'ns.balabit' ],
    'Support ns record working'
);

#$dns_core->is_ptr( '10.21.0.23' => 'support.balabit', 'Support ns record working' );
done_testing;
