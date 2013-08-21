#!/usr/bin/perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use SDK::Support;

sub longest {
    my ($array) = @_;
    my $max = -1;
    for (@$array) {
        if (length > $max) {
            $max = length;
        }
    }
    return $max;
}

my @sorted;
while ( my ($keys) = each (%Support::template_hash)) {
	push(@sorted,$keys);
}
@sorted = sort @sorted;
my $longest = &longest(\@sorted);

for (@sorted) {
	Util::trace( 0, "Name:'$_'" );
	my $length = length;
	$length = ($longest - $length) +1;
	Util::trace( 0, " " x $length );
	Util::trace( 0, "Path: $Support::template_hash{$_}{'path'}\n" );
}
