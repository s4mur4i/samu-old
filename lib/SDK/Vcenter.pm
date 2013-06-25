package Vcenter;

use strict;
use warnings;
use Data::Dumper;

BEGIN {
        use Exporter;
        our @ISA = qw(Exporter);
        our @EXPORT = qw( &test );
        our @EXPORT_OK = qw( &test );
}

sub test() {
        print "Vcenter module test sub\n";
}

#### We need to end with success
1
