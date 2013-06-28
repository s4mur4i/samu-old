package Vcenter;

use strict;
use warnings;
use Data::Dumper;

BEGIN {
        use Exporter;
        our @ISA = qw(Exporter);
        our @EXPORT = qw( &test &mac_compare );
        our @EXPORT_OK = qw( &test &mac_compare );
}

## Searches all virtual machines mac address if mac address is already used
## Parameters:
##  mac: mac address to search format: xx:xx:xx:xx:xx:xx
## Returns:
##  true or false according to success

sub mac_compare {
        my ($mac) = @_;
        my $vm_view = Vim::find_entity_views(view_type => 'VirtualMachine',properties =>['config.hardware.device','summary.config.name']);

        foreach(@$vm_view) {
                my $vm_name = $_->get_property('summary.config.name');
                my $devices =$_->get_property('config.hardware.device');
                foreach(@$devices) {
                        if($_->isa("VirtualEthernetCard")) {
                                if ( $mac eq $_->macAddress ) {
                                        return 1;
                                }
                        }
                }
        }
        return 0;
}

## Functionality test sub
sub test() {
        print "Vcenter module test sub\n";
}

#### We need to end with success
1
