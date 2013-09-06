#!/usr/bin/perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Pod::Simple::Wiki::Dokuwiki;

my $parser = Pod::Simple::Wiki->new('dokuwiki');

open( my $IN,  "<", $ARGV[0] ) or die "Couldn't open $ARGV[0]: $!\n";
open( my $OUT, ">", $ARGV[1] ) or die "Couldn't open $ARGV[1]: $!\n";

$parser->output_fh($OUT);
$parser->parse_file($IN);

__END__
