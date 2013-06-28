package GuestManagement;

use strict;
use warnings;
use Data::Dumper;
use SDK::Misc;

BEGIN {
        use Exporter;
        our @ISA = qw(Exporter);
        our @EXPORT = qw( &test &add_network_interface &count_network_interface &remove_network_interface &get_network_interface );
        our @EXPORT_OK = qw( &test &add_network_interface &count_network_interface &remove_network_interface &get_network_interface );
}

## Add network interface to vm
## Parameters:
##  vmname: name of vm
## Returns:
##

sub add_network_interface {
	## Incremented mac should be tested
	my ($vmname) = @_;
	my $int_count = &count_network_interface($vmname);
	print "Count $int_count\n";
	my ($key, $unitnumber, $controllerkey, $mac) = &get_network_interface($vmname,$int_count-1);
	print "info: $key, $unitnumber,$controllerkey, $mac\n";
	$mac = &Misc::increment_mac($mac);
	$key++;
	## Add to default VLAN 21 interface
	my $switch = Vim::find_entity_view( view_type => 'Portgroup', filter => { 'name' => "VLAN21" });
	print Dumper($switch);
	#$vmname = Vim::find_entity_view(view_type=>'VirtualMachine', filter=> {name => $vmname});
	#my $port = DistributedVirtualSwitchPortConnection->new(switchUuid=>$dvs_uuid);
	#my $backing = VirtualEthernetCardDistributedVirtualPortBackingInfo->new(port=>$port);
	#my $device = VirtualE1000->new( connectable=>VirtualDeviceConnectInfo->new( startConnected =>'1', allowGuestControl =>'1', connected => '1') ,wakeOnLanEnabled =>1, macAddress=>$mac , addressType=>"Manual", key=>$key , backing=>$backing);
	#my $deviceconfig = VirtualDeviceConfigSpec->new( operation=> VirtualDeviceConfigSpecOperation->new('add'), device=> $device);
	#my $spec = VirtualMachineConfigSpec->new( deviceChange=>[$deviceconfig]);
}

## Return number of VirtualE1000 interfaces
## Parameters:
##  vmname: name of vm
## Returns:
##  count: number of network interfaces

sub count_network_interface {
	my ($vmname) =@_;
	$vmname = Vim::find_entity_view(view_type=>'VirtualMachine', filter=> {name => $vmname});
        my $count=0;
        foreach ( @{$vmname->config->hardware->device}) {
                my $interface = $_;
                if ( $interface->isa('VirtualE1000')) {
			$count++;
                }
        }
        return $count;
}

## Remove network interface from vm
## Parameters:
##  vmname: name of vm
##  num: number of interface to remove
## Returns:
##

sub remove_network_interface {
	my ($vmname,$num) = @_;
	my ($key, $unitnumber, $controllerkey, $mac) = &get_network_interface($vmname,$num);
	$vmname = Vim::find_entity_view(view_type=>'VirtualMachine', filter=> {name => $vmname});
}

## Return Information about network interface
## Parameters:
##  vmname: name of vm
##  num: number of interface to return information about (starts at 0)
## Returns:
##  key: device ID key
##  unitnumber: Unitnumber on controller
##  controllerkey: Key of controller
##  mac: mac address of interface

sub get_network_interface {
        my ($vmname,$num) = @_;
	$vmname = Vim::find_entity_view(view_type=>'VirtualMachine', filter=> {name => $vmname});
        my @keys;
        my @unitnumber;
        my @controllerkey;
        my @mac;
        foreach ( @{$vmname->config->hardware->device}) {
                my $interface = $_;
                if ( !$interface->isa('VirtualE1000')) {
                        next;
                }
                push(@keys,$interface->key);
                push(@unitnumber,$interface->unitNumber);
                push(@controllerkey,$interface->controllerKey);
                push(@mac,$interface->macAddress);
        }
        return ($keys[$num],$unitnumber[$num],$controllerkey[$num],$mac[$num]);
}

## Functionality test sub

sub test() {
        print "GuestManagement module test sub\n";
}

#### We need to end with success
1
