package Auto;

use strict;
use warnings;
use Data::Dumper;

BEGIN {
        use Exporter;
        our @ISA = qw( Exporter );
        our @EXPORT = qw( &test %dns &install_puppet );
}

our %dns = (
	prod_ad => { vmname => 'DC_PROD', username => 'Administrator@ittest.balabit', password => 'Password123', domain => 'ittest.balabit' },
	dev_ad => { vmname => 'DC-DEV', username => 'Administrator@support.balabit', password => 'titkos', domain => 'support.balabit' },
);

sub install_puppet {
	my ( $vmname ) = @_;
}

sub test() {
        print "Automatisation module test sub\n";
}

#### We need to end with success
1
