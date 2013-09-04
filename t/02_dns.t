#!/usr/bin/perl

BEGIN {
  if ($ENV{NO_DNS}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing with DNS');
  }
}

use strict;
use warnings;
use 5.14.0;
use Test::More;
use Test::DNS;

my $dns_core = Test::DNS->new( nameservers => [ '10.10.0.1' ] );
my $dns_support = Test::DNS->new( nameservers => [ '10.10.0.1' ] );
$dns_support->is_a( 'support.balabit' => '10.21.0.23', 'Support can resolve itself' );
$dns_core->is_a( 'support.balabit' => '10.21.0.23', 'Support can be resolved by core' );
$dns_core->is_ns( 'support.balabit' => [ 'dc-dev.support.balabit', 'ns.balabit' ], 'Support ns record working' );
#$dns_core->is_ptr( '10.21.0.23' => 'support.balabit', 'Support ns record working' );
done_testing;
