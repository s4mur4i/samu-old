#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
use Module::Load;

my @error;
my $count = 0;

sub test {
    my ( $var, $name ) = @_;
    if ( $var && $name !~ /^Test/ ) {
        print "$name error\n";
        print Dumper($var);
        push( @error, $name );
    }
    elsif ( $var && $name =~ /^Test/ && $ENV{TEST} ) {
        print "Test Module found: $name\n";
        print Dumper($var);
        push( @error, $name );
    }
    else {
        print "$name loaded succesfully\n";
    }
}

sub req {
    my ($name) = @_;
    $count++;
    eval { load $name; };
    &test( $@, $name );
}

open( my $fh, "<", "PERL_MODULES" ) || die "Can't open file: $!\n";
my @modules;
while (<$fh>) {
    chomp $_;
    push( @modules, $_ );
}
close $fh;
foreach (@modules) {
    print "Testing module: $_\n";
    &req($_);
}
print "#### Summary BEGIN ####\n";
print "Tested $count perl modules\n";
if ( @error ne 0 ) {
    print "There were " . @error . " errors\n";
    print "Need to fix problems with: " . join( ", ", @error ) . "\n";
}
else {
    print "Everything ok.\n";
}
print "#### Summary END ####\n";
