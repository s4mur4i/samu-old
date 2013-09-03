#!/usr/bin/perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Pod::Simple::Wiki::Dokuwiki;

my $parser = Pod::Simple::Wiki->new('dokuwiki');

if ( defined $ARGV[0] ) {
    open IN, $ARGV[0] or die "Couldn't open $ARGV[0]: $!\n";
}
else {
    *IN = *STDIN;
}

if ( defined $ARGV[1] ) {
    open OUT, ">$ARGV[1]" or die "Couldn't open $ARGV[1]: $!\n";
}
else {
    *OUT = *STDOUT;
}

$parser->output_fh(*OUT);
$parser->parse_file(*IN);

__END__
