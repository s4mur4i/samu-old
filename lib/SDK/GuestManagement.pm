package GuestManagement;

use strict;
use warnings;
use Data::Dumper;
use SDK::Misc;
use SDK::Vcenter;

BEGIN {
        use Exporter;
        our @ISA = qw(Exporter);
        our @EXPORT = qw( &test &add_network_interface &count_network_interface &remove_network_interface &get_network_interface &get_ext_network_interface &change_network_interface &list_dvportgroup &create_dvportgroup &remove_dvportgroup &dvportgroup_status &list_networks );
        our @EXPORT_OK = qw( &test &add_network_interface &count_network_interface &remove_network_interface &get_network_interface &get_ext_network_interface &change_network_interface &list_dvportgroup &create_dvportgroup &remove_dvportgroup &dvportgroup_status &list_networks );
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
	my ($key, $unitnumber, $controllerkey, $mac) = &get_network_interface($vmname,$int_count-1);
	$mac = &Misc::increment_mac($mac);
	$key++;
	## Add to default VLAN 21 interface
	my $switch = Vim::find_entity_view( view_type=> 'Network',filter => { 'name' => "VLAN21" });
	$vmname = Vim::find_entity_view(view_type=>'VirtualMachine', filter=> {name => $vmname});
	my $backing = VirtualEthernetCardNetworkBackingInfo->new(deviceName=>$switch->name, network=>$switch);
	my $device = VirtualE1000->new( connectable=>VirtualDeviceConnectInfo->new(startConnected =>'1', allowGuestControl =>'1', connected => '1') ,wakeOnLanEnabled =>1, macAddress=>$mac , addressType=>"Manual", key=>$key , backing=>$backing, deviceInfo=>Description->new(summary=>'VLAN21', label=>''));
	my $deviceconfig = VirtualDeviceConfigSpec->new(operation=> VirtualDeviceConfigSpecOperation->new('add'), device=> $device);
	my $spec = VirtualMachineConfigSpec->new( deviceChange=>[$deviceconfig]);
	my $task = $vmname->ReconfigVM_Task(spec=>$spec);
	## Wait for task to complete
	&Vcenter::Task_getStatus($task);
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
	my $device = VirtualE1000->new(key=>$key);
        my $deviceconfig = VirtualDeviceConfigSpec->new(operation=> VirtualDeviceConfigSpecOperation->new('remove'), device=> $device);
        my $spec = VirtualMachineConfigSpec->new( deviceChange=>[$deviceconfig]);
	$vmname->ReconfigVM_Task(spec=>$spec);
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

## Get further information about network interface
## Parameters:
##  vmname: name of vm
##  num: number of interface to return information about (starts at 0)
## Returns:
##  network: Network name
##  label: Network interface label

sub get_ext_network_interface {
	my ($vmname,$num) = @_;
        $vmname = Vim::find_entity_view(view_type=>'VirtualMachine', filter=> {name => $vmname});
	my @network;
	my @label;
	foreach ( @{$vmname->config->hardware->device}) {
                my $interface = $_;
                if ( !$interface->isa('VirtualE1000')) {
                        next;
                }
		push(@network,$interface->backing->deviceName);
		push(@label,$interface->deviceInfo->label);
        }
	return ($network[$num],$label[$num]);
}

sub change_network_interface {
	my ($vmname,$num,$network) = @_;
	my ($key, $unitnumber, $controllerkey, $mac) = &get_network_interface($vmname,$num);
	$vmname = Vim::find_entity_view(view_type=>'VirtualMachine', filter=> {name => $vmname});
	$network = Vim::find_entity_view( view_type=> 'Network',filter => { name=> $network });
	if ( !defined($network)) {
		print "Cannot find network\n";
		exit 15;
	}
        my $backing = VirtualEthernetCardNetworkBackingInfo->new(deviceName=>$network->name, network=>$network);
        my $device = VirtualE1000->new( connectable=>VirtualDeviceConnectInfo->new(startConnected =>'1', allowGuestControl =>'1', connected => '1') ,wakeOnLanEnabled =>1, macAddress=>$mac , addressType=>"Manual", key=>$key , backing=>$backing, deviceInfo=>Description->new(summary=>$network->name, label=>''));
        my $deviceconfig = VirtualDeviceConfigSpec->new(operation=> VirtualDeviceConfigSpecOperation->new('edit'), device=> $device);
        my $spec = VirtualMachineConfigSpec->new( deviceChange=>[$deviceconfig]);
        $vmname->ReconfigVM_Task(spec=>$spec);

}

## Create switch to hold port groups
## Parameters:
##  name: how to name the switch. Default: ticket
## Returns:
##

sub create_switch {
	my ($name) = @_;
	my $root_folder = Vim::find_entity_view( view_type => 'Folder', filter => {name => 'network'});
        my $host_view = Vim::find_entity_view(view_type => 'HostSystem', filter => { name => 'vmware-it1.balabit'});
        my $hostspec = DistributedVirtualSwitchHostMemberConfigSpec->new(operation=>'add', maxProxySwitchPorts=>99,host=>$host_view);
        my $dvsconfigspec = DVSConfigSpec->new(name=>$name, maxPorts=>300,description=>"DVS for ticket $name",host=>[$hostspec]);
        my $spec = DVSCreateSpec->new(configSpec=>$dvsconfigspec);
        my $task = $root_folder->CreateDVS_Task(spec=>$spec);
	&Vcenter::Task_getStatus($task);
}

sub remove_switch {
	my ($name) = @_;
	my $switch = Vim::find_entity_view( view_type => 'DistributedVirtualSwitch', filter=>{ name=>$name});
	my $task = $switch->Destroy_Task;
	&Vcenter::Task_getStatus($task);
}

## Create a distributed port group
## Parameters:
##  name: name of dv portgroup
##  switch: name of switch were to add the port group
## Returns:
##

sub create_dvportgroup {
	my ($name,$switch) = @_;
	my $switch_view = Vim::find_entity_view( view_type => 'DistributedVirtualSwitch', filter => { 'name' => $switch });
	if (!defined($switch_view)) {
		&create_switch($switch);
		$switch_view = Vim::find_entity_view( view_type => 'DistributedVirtualSwitch', filter => { 'name' => $switch });
	}
	my $spec = DVPortgroupConfigSpec->new(name=>$name, type=>'earlyBinding',numPorts=>20,description=>"Self created port group");
        my $task = $switch_view->AddDVPortgroup_Task(spec=>$spec);
	&Vcenter::Task_getStatus($task);
}

sub remove_dvportgroup {
	my ($name) = @_;
	my $portgroup = Vim::find_entity_view( view_type => 'DistributedVirtualPortgroup', filter=>{ name=>$name});
	my $parent_switch = $portgroup->config->distributedVirtualSwitch;
	$parent_switch = Vim::get_view( mo_ref => $parent_switch);
	my $count = $parent_switch->summary->portgroupName;
	if ( @$count < 3 ) {
		print "Last portgroup, need to remove DV switch\n";
		&remove_switch($parent_switch->name);
	} else {
		my $task = $portgroup->Destroy_Task;
		&Vcenter::Task_getStatus($task);
	}
}

## Check if dv port group exists
## Parameters:
##  name: name of port group to check
## Returns:
##  boolean: True if exists false if not

sub dvportgroup_status {
	my ($name) = @_;
	my $network = Vim::find_entity_view( view_type=> 'Network',filter => { 'name' => $name });
	if (defined($network)) {
		return 1;
	} else {
		return 0;
	}
}

sub list_networks {
	my $networks = Vim::find_entity_views( view_type=> 'Network');
	foreach(@$networks) {
                print "name:'" . $_->name ."'\n";
        }
}

## List all networks on esx.. Maybe rename sub to better fit purpose
## Parameters:
##
## Returns:
##

sub list_dvportgroup {
	my $networks = Vim::find_entity_views( view_type => 'DistributedVirtualPortgroup');
	foreach(@$networks) {
		print "name:'" . $_->name ."'\n";
	}
}

## Functionality test sub

sub test() {
        print "GuestManagement module test sub\n";
}

#### We need to end with success
1
