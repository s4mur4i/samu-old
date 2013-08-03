package Hardware;

use strict;
use warnings;
use Data::Dumper;

BEGIN {
        use Exporter;
        our @ISA = qw( Exporter );
        our @EXPORT = qw( &test );
}

sub test() {
        print "Hardware module test sub\n";
}

#### We need to end with success
1
