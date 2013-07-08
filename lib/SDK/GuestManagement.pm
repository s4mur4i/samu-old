package GuestManagement;

use strict;
use warnings;
use Data::Dumper;
use SDK::Misc;
use SDK::Vcenter;
use SDK::Support;

BEGIN {
        use Exporter;
        our @ISA = qw(Exporter);
        our @EXPORT = qw( &test &add_network_interface &count_network_interface &remove_network_interface &get_network_interface &get_ext_network_interface &change_network_interface &list_dvportgroup &create_dvportgroup &remove_dvportgroup &dvportgroup_status &list_networks &CustomizationAdapterMapping_generator &add_disk &remove_disk &get_cdrom &remove_cdrom);
#        our @EXPORT_OK = qw( &test &add_network_interface &count_network_interface &remove_network_interface &get_network_interface &get_ext_network_interface &change_network_interface &list_dvportgroup &create_dvportgroup &remove_dvportgroup &dvportgroup_status &list_networks &CustomizationAdapterMapping_generator &add_disk );
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
	#my $task = $vmname->ReconfigVM_Task(spec=>$spec);
	## Wait for task to complete
	#&Vcenter::Task_getStatus($task);
}

sub add_disk {
        my ($vmname,$req_size) = @_;
	my $view = Vim::find_entity_view(view_type=>'VirtualMachine',filter=>{name=>$vmname});
        my $disk_count = &count_disk($vmname);
        my ($key, $size, $path) = &get_disk($vmname,$disk_count-1);
	my $controller = &get_scsi_controller($vmname);
	my $controller_key = $controller->key;
	my $unitnumber = $#{$controller->device} + 1;
	if ($unitnumber < 7) {
		print "Not yet reached controllerID\n";
	} elsif ($unitnumber == 15) {
		print "ERR: one SCSI controller cannot have more than 15 virtual disks\n";
		return 0;
	} else {
		$unitnumber++;
	}
        $key++;
	my $inc_path = &Misc::increment_disk_name($path);
	my $disk_backing_info = VirtualDiskFlatVer2BackingInfo->new(fileName => $inc_path, diskMode => "persistent", thinProvisioned=>1 );
	my $disk = VirtualDisk->new(controllerKey => $controller_key, unitNumber => $unitnumber, key => -1, backing => $disk_backing_info, capacityInKB => $req_size );
	my $devspec = VirtualDeviceConfigSpec->new(operation => VirtualDeviceConfigSpecOperation->new('add'), device => $disk, fileOperation=>VirtualDeviceConfigSpecFileOperation->new('create') );
	my $vmspec = VirtualMachineConfigSpec->new(deviceChange => [$devspec] );
	print "Adding disk to machine.\n";
        my $task = $view->ReconfigVM_Task(spec=>$vmspec);
        ## Wait for task to complete
        &Vcenter::Task_getStatus($task);
}

sub add_cdrom {
        my ($vmname) = @_;
        my $view = Vim::find_entity_view(view_type=>'VirtualMachine',filter=>{name=>$vmname});
        my $cdrom_count = &count_cdrom($vmname);
	my $ide_key = &get_free_ide_controller($vmname);
        my ($key, $backing, $label) = &get_disk($vmname,$cdrom_count-1);
        $key++;
	my $cdrombacking = VirtualCdromRemotePassthroughBackingInfo->new(exclusive=>0,deviceName=>'');
	my $cdrom = VirtualCdrom->new(key=>$key,backing=>$cdrombacking,controllerKey=>$ide_key);
        my $devspec = VirtualDeviceConfigSpec->new(operation => VirtualDeviceConfigSpecOperation->new('add'), device => $cdrom, );
        my $vmspec = VirtualMachineConfigSpec->new(deviceChange => [$devspec] );
        print "Adding cdrom to machine.\n";
        my $task = $view->ReconfigVM_Task(spec=>$vmspec);
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

sub count_cdrom {
        my ($vmname) =@_;
        $vmname = Vim::find_entity_view(view_type=>'VirtualMachine', filter=> {name => $vmname});
        my $count=0;
        foreach ( @{$vmname->config->hardware->device}) {
                my $disk = $_;
                if ( $disk->isa('VirtualCdrom')) {
                        $count++;
                }
        }
        return $count;
}


sub count_disk {
        my ($vmname) =@_;
        $vmname = Vim::find_entity_view(view_type=>'VirtualMachine', filter=> {name => $vmname});
        my $count=0;
        foreach ( @{$vmname->config->hardware->device}) {
                my $disk = $_;
                if ( $disk->isa('VirtualDisk')) {
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

sub remove_disk {
        my ($vmname,$num) = @_;
	my ($key, $size, $path) = &get_disk($vmname,$num);
        $vmname = Vim::find_entity_view(view_type=>'VirtualMachine', filter=> {name => $vmname});
        my $device = VirtualDisk->new(key=>$key, capacityInKB=> "1");
        my $deviceconfig = VirtualDeviceConfigSpec->new(operation=> VirtualDeviceConfigSpecOperation->new('remove'), device=> $device, fileOperation=>VirtualDeviceConfigSpecFileOperation->new('destroy'));
        my $spec = VirtualMachineConfigSpec->new( deviceChange=>[$deviceconfig]);
        $vmname->ReconfigVM_Task(spec=>$spec);
}

sub remove_cdrom {
        my ($vmname,$num) = @_;
        my ($key,$backing, $label) = &get_cdrom($vmname,$num);
        $vmname = Vim::find_entity_view(view_type=>'VirtualMachine', filter=> {name => $vmname});
        my $device = VirtualCdrom->new(key=>$key);
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

sub get_disk {
        my ($vmname,$num) = @_;
        $vmname = Vim::find_entity_view(view_type=>'VirtualMachine', filter=> {name => $vmname});
        my @keys;
	my @size;
	my @path;
        foreach ( @{$vmname->config->hardware->device}) {
                my $disk = $_;
                if ( !$disk->isa('VirtualDisk')) {
                        next;
                }
                push(@keys,$disk->key);
		push(@size,$disk->capacityInKB);
		push(@path,$disk->backing->fileName);
        }
        return ($keys[$num],$size[$num],$path[$num]);
}

sub get_cdrom {
        my ($vmname,$num) = @_;
        $vmname = Vim::find_entity_view(view_type=>'VirtualMachine', filter=> {name => $vmname});
        my @keys;
        my @backing;
        my @label;
        foreach ( @{$vmname->config->hardware->device}) {
                my $cdrom = $_;
                if ( !$cdrom->isa('VirtualCdrom')) {
                        next;
                }
                push(@keys,$cdrom->key);
		if ($cdrom->backing->isa('VirtualCdromIsoBackingInfo')) {
			push(@backing,$cdrom->backing->fileName);
		} elsif ( $cdrom->backing->isa('VirtualCdromRemotePassthroughBackingInfo')) {
			push(@backing,"Host device");
		} else {
			push(@backing,"Unknown");
		}
                push(@label,$cdrom->deviceInfo->label);
        }
        return ($keys[$num],$backing[$num],$label[$num]);
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

## Changes the attached network to a network interface
## Parameters:
##  vmname: name of vm
##  num: number of interface to do changes
##  network: name of network to change the interface to
## Returns:
##

sub change_network_interface {
	my ($vmname,$num,$network) = @_;
	my ($key, $unitnumber, $controllerkey, $mac) = &get_network_interface($vmname,$num);
	$vmname = Vim::find_entity_view(view_type=>'VirtualMachine', filter=> {name => $vmname});
	my $network_view = Vim::find_entity_view( view_type => 'DistributedVirtualPortgroup', filter => {name => $network});
	my $backing;
	if (!defined($network_view)) {
		$network = Vim::find_entity_view( view_type=> 'Network',filter => { name=> $network });
		if ( !defined($network)) {
			print "Cannot find network\n";
			exit 15;
		}
		$backing = VirtualEthernetCardNetworkBackingInfo->new(deviceName=>$network->name, network=>$network);
	} else {
		$network = $network_view;
		my $switch = Vim::get_view( mo_ref => $network->config->distributedVirtualSwitch);
		my $port = DistributedVirtualSwitchPortConnection->new(portgroupKey=>$network->key, switchUuid=>$switch->uuid);
		$backing = VirtualEthernetCardDistributedVirtualPortBackingInfo->new(port=>$port);
	}
        my $device = VirtualE1000->new( connectable=>VirtualDeviceConnectInfo->new(startConnected =>'1', allowGuestControl =>'1', connected => '1') ,wakeOnLanEnabled =>1, macAddress=>$mac , addressType=>"Manual", key=>$key , backing=>$backing, deviceInfo=>Description->new(summary=>$network->name, label=>$network->name));
        my $deviceconfig = VirtualDeviceConfigSpec->new(operation=> VirtualDeviceConfigSpecOperation->new('edit'), device=> $device);
        my $spec = VirtualMachineConfigSpec->new( deviceChange=>[$deviceconfig]);
        my $task = $vmname->ReconfigVM_Task(spec=>$spec);
	&Vcenter::Task_getStatus($task);
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

## Deletes switch from esx
## Parameters:
##  name: name of switch
## Returns:
##

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
	my $test = Vim::find_entity_view( view_type => 'DistributedVirtualPortgroup', filter => {name => $name});
	if ( !defined($test)) {
		my $spec = DVPortgroupConfigSpec->new(name=>$name, type=>'earlyBinding',numPorts=>20,description=>"Port group");
		my $task = $switch_view->AddDVPortgroup_Task(spec=>$spec);
		&Vcenter::Task_getStatus($task);
	}
}

## Removes dvportgroup , if last, then the switch aswell
## Parameters:
##  name: name of port group to check
## Returns:
##

sub remove_dvportgroup {
	my ($name) = @_;
	my $portgroup = Vim::find_entity_view( view_type=> 'DistributedVirtualPortgroup', filter =>{name =>$name});
	my $parent_switch = $portgroup->config->distributedVirtualSwitch;
	$parent_switch = Vim::get_view( mo_ref => $parent_switch);
	my $count = $parent_switch->summary->portgroupName;
	if (@$count < 3 ) {
		print "Last portgroup, need to remove DV switch\n";
		&remove_switch($parent_switch->name);
	} else {
		my $task = $portgroup->Destroy_Task;
		&Vcenter::Task_getStatus($task);
	}
}

sub dvportgroup_status {
	my ($name) = @_;
	my $network = Vim::find_entity_view( view_type=> 'Network',filter => { 'name' => $name });
	if (defined($network)) {
		return 1;
	} else {
		return 0;
	}
}

## List all networks on esx..
## Parameters:
##
## Returns:
##

sub list_networks {
	my $networks = Vim::find_entity_views( view_type=> 'Network');
	foreach(@$networks) {
                print "name:'" . $_->name ."'\n";
        }
}

## List all dvportgroups on esx..
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

sub CustomizationAdapterMapping_generator {
	my ($os) = @_;
	my @return;
	if ( defined($Support::template_hash{$os})) {
		my $source_temp = $Support::template_hash{$os}{'path'};
		$source_temp = &Vcenter::path_to_moref($source_temp);
		foreach ( @{$source_temp->config->hardware->device}) {
                        if ( !$_->isa('VirtualE1000')) {
                                next;
                        }
                        my $ip = CustomizationDhcpIpGenerator->new();
                        my $adapter = CustomizationIPSettings->new(dnsDomain=>'support.balabit',dnsServerList=>['10.21.0.23'],gateway=>['10.21.255.254'],subnetMask=>'255.255.0.0', ip=>$ip);
                        my $nicsetting = CustomizationAdapterMapping->new(adapter=>$adapter);
                        push(@return,$nicsetting);
                }

	} else {
		print "Cannot find template\n";
		return 0;
	}
	return \@return;
}

sub get_scsi_controller {
	my ($name) = @_;
	my $vm_view = Vim::find_entity_view(view_type=>'VirtualMachine',filter=>{name=>$name});
	my $controller;
	my $num_controller = 0;
	foreach (@{$vm_view->config->hardware->device}) {
		if (ref($_) =~ /VirtualBusLogicController|VirtualLsiLogicController|VirtualLsiLogicSASController|ParaVirtualSCSIController/) {
		$num_controller++;
		$controller = $_;
		}
	}
	if ($num_controller != 1) {
		print "Problem with controller count\n";
		return 0;
	}
	return $controller;
}

#VirtualIDEController

sub get_free_ide_controller {
	my ($name) = @_;
        my $vm_view = Vim::find_entity_view(view_type=>'VirtualMachine',filter=>{name=>$name});
        my @controller;
        my $num_controller = 0;
	foreach (@{$vm_view->config->hardware->device}) {
		if (ref($_) =~ /VirtualIDEController/ ) {
			$num_controller++;
			push(@controller,$_);
		}
	}
	foreach (@controller) {
		if (defined($_->device)) {
			if (@{$_->device} lt 2) {
				return $_->key;
			}
		} else {
			return $_->key;
		}
	}
	print "Ide controllers full. Cannot add further devices\n";
	return 0;
}

## Functionality test sub

sub test() {
        print "GuestManagement module test sub\n";
}

#### We need to end with success
1
