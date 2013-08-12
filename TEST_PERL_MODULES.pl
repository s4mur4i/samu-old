#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;

sub test {
	my ( $var, $name) = @_;
	if ( $var ) {
		print "$name error\n";
		print Dumper( $var );
	} else {
		print "$name loaded succesfully\n";
	}
}

sub req {
	my ( $name ) = @_;
	eval "require $name";
	&test( $@, $name );
}

open ( my $fh, "<", "PERL_MODULES") || die "Can't open file: $!\n";
my @modules;
while (  <$fh> ) {
	chomp $_;
	push( @modules, $_);
}
close $fh;
foreach ( @modules) {
	print "Testing module: $_\n";
	&req($_);
}
