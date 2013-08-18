package GuestManagement;

use strict;
use warnings;
use Data::Dumper;
use SDK::Misc;
use SDK::Vcenter;
use SDK::Support;
use SDK::Error;

BEGIN {
	use Exporter;
	our @ISA = qw( Exporter );
	our @EXPORT = qw( &test &add_network_interface &count_network_interface &remove_network_interface &get_network_interface &get_ext_network_interface &change_network_interface &list_dvportgroup &create_dvportgroup &remove_dvportgroup &dvportgroup_status &list_networks &CustomizationAdapterMapping_generator &add_disk &remove_disk &get_cdrom &remove_cdrom &change_cdrom_to_iso &remove_cdrom_iso &create_snapshot &list_snapshot &change_altername &poweroff_vm poweron_vm &promote_vdisk &move_into_folder );
}

## Add network interface to vm
## Parameters:
##  vmname: name of vm
## Returns:
##

sub add_network_interface {
	## Incremented mac should be tested
	my ( $vmname ) = @_;
	my $int_count = &count_network_interface( $vmname );
	my ( $key, $unitnumber, $controllerkey, $mac ) = &get_network_interface( $vmname, $int_count-1 );
	$mac = &Misc::increment_mac( $mac );
	$key++;
	## Add to default VLAN 21 interface
	my $switch = Vim::find_entity_view( view_type => 'Network', properties => [ 'name' ], filter => { name => "VLAN21" } );
	if ( !defined( $switch ) ) {
		SDK::Error::Entity::NumException->throw( error => 'Could not find switch', entity => 'VLAN21', count => '0' );
	}
	my $view = Vim::find_entity_view( view_type => 'VirtualMachine', properties => [ 'name' ], filter => { name => $vmname } );
	if ( !defined( $view ) ) {
		SDK::Error::Entity::NumException->throw( error => 'Could not find vm entity', entity => $vmname, count => '0' );
	}
	my $backing = VirtualEthernetCardNetworkBackingInfo->new( deviceName => $switch->name, network => $switch );
	my $device = VirtualE1000->new( connectable => VirtualDeviceConnectInfo->new( startConnected => '1', allowGuestControl => '1', connected => '1' ), wakeOnLanEnabled => 1, macAddress => $mac, addressType => "Manual", key => $key, backing => $backing, deviceInfo => Description->new( summary => 'VLAN21', label => '' ) );
	my $deviceconfig = VirtualDeviceConfigSpec->new( operation => VirtualDeviceConfigSpecOperation->new( 'add' ), device => $device );
	my $spec = VirtualMachineConfigSpec->new( deviceChange => [ $deviceconfig ] );
	my $task = $view->ReconfigVM_Task( spec => $spec );
	&Vcenter::Task_getStatus( $task );
}

sub add_disk {
	my ( $vmname, $req_size ) = @_;
	my $view = Vim::find_entity_view( view_type => 'VirtualMachine', properties => [ 'name' ], filter => { name => $vmname } );
	if ( !defined( $view ) ) {
		SDK::Error::Entity::NumException->throw( error => 'Could not find VM entity', entity => $vmname, count => '0' );
	}
	my $disk_count = &count_disk( $vmname );
	my ( $key, $size, $path ) = &get_disk( $vmname, $disk_count-1 );
	my $controller = &get_scsi_controller( $vmname );
	my $controller_key = $controller->key;
	my $unitnumber = $#{ $controller->device } + 1;
	if ( $unitnumber < 7 ) {
		print "Not yet reached controllerID\n";
	} elsif ( $unitnumber == 15 ) {
		SDK::Error::Entity::HWError->throw( error => 'SCSI controller has already 15 disks', entity => $vmname, hw => 'SCSI Controller' );
	} else {
		$unitnumber++;
	}
	$key++;
	my $inc_path = &Misc::increment_disk_name( $path );
	my $disk_backing_info = VirtualDiskFlatVer2BackingInfo->new( fileName => $inc_path, diskMode => "persistent", thinProvisioned => 1 );
	my $disk = VirtualDisk->new( controllerKey => $controller_key, unitNumber => $unitnumber, key => -1, backing => $disk_backing_info, capacityInKB => $req_size );
	my $devspec = VirtualDeviceConfigSpec->new( operation => VirtualDeviceConfigSpecOperation->new( 'add' ), device => $disk, fileOperation => VirtualDeviceConfigSpecFileOperation->new( 'create' ) );
	my $vmspec = VirtualMachineConfigSpec->new( deviceChange => [ $devspec ] );
	print "Adding disk to machine.\n";
	my $task = $view->ReconfigVM_Task( spec => $vmspec );
	&Vcenter::Task_getStatus( $task );
}

sub add_cdrom {
	my ( $vmname ) = @_;
	my $view = Vim::find_entity_view( view_type => 'VirtualMachine', properties => [ 'name' ], filter => { name => $vmname } );
	if ( !defined( $view ) ) {
		SDK::Error::Entity::NumException->throw( error => 'Could not find VM entity', entity => $vmname, count => '0' );
	}
	my $cdrom_count = &count_cdrom( $vmname );
	my $ide_key = &get_free_ide_controller( $vmname );
	my ( $key, $backing, $label ) = &get_disk( $vmname, $cdrom_count-1 );
	$key++;
	my $cdrombacking = VirtualCdromRemotePassthroughBackingInfo->new( exclusive => 0, deviceName => '' );
	my $cdrom = VirtualCdrom->new( key => $key, backing => $cdrombacking, controllerKey => $ide_key );
	my $devspec = VirtualDeviceConfigSpec->new( operation => VirtualDeviceConfigSpecOperation->new( 'add' ), device => $cdrom, );
	my $vmspec = VirtualMachineConfigSpec->new( deviceChange => [ $devspec ] );
	print "Adding cdrom to machine.\n";
	my $task = $view->ReconfigVM_Task( spec => $vmspec );
	&Vcenter::Task_getStatus( $task );
}

sub change_cdrom_to_iso {
	my ( $vmname, $num, $filename ) = @_;
	if ( !&Vcenter::datastore_file_exists( $filename ) ) {
		SDK::Error::Entity::Path->throw( error => 'File does not exist on datastore', path => $filename );
	}
	my ( $datas, $folder, $image ) = &Misc::filename_splitter( $filename );
	my $view = Vim::find_entity_view( view_type => 'VirtualMachine', properties => [ 'name' ], filter => { name => $vmname } );
	if ( !defined( $view ) ) {
		SDK::Error::Entity::NumException->throw( error => 'Could not retrieve VM entity', entity => $vmname, count => '0' );
	}
	my ( $key, $backing, $label ) = &get_cdrom( $vmname, $num );
	my $controllerkey = &get_controller_key( $vmname, $key );
	my $isobacking = VirtualCdromIsoBackingInfo->new( fileName => $filename );
	my $device = VirtualCdrom->new( backing => $isobacking, key => $key, controllerKey => $controllerkey );
	my $configspec = VirtualDeviceConfigSpec->new( device => $device, operation => VirtualDeviceConfigSpecOperation->new( 'edit' ) );
	my $spec = VirtualMachineConfigSpec->new( deviceChange => [ $configspec ] );
	my $task = $view->ReconfigVM_Task( spec => $spec );
	&Vcenter::Task_getStatus( $task );
}

sub remove_cdrom_iso {
	my ( $vmname, $num ) = @_;
	my ( $key, $backing, $label ) = &get_cdrom( $vmname, $num );
	my $controllerkey = &get_controller_key( $vmname, $key );
	my $view = Vim::find_entity_view( view_type => 'VirtualMachine', properties => [ 'name' ], filter => { name => $vmname } );
	if ( !defined( $view ) ) {
		SDK::Error::Entity::NumException->throw( error => 'Could not retrieve VM entity', entity => $vmname, count => '0' );
	}
	my $normbacking = VirtualCdromRemotePassthroughBackingInfo->new( exclusive => 0, deviceName => '' );
	my $device = VirtualCdrom->new( backing => $normbacking, key => $key, controllerKey => $controllerkey );
	my $configspec = VirtualDeviceConfigSpec->new( device => $device, operation => VirtualDeviceConfigSpecOperation->new( 'edit' ) );
	my $spec = VirtualMachineConfigSpec->new( deviceChange => [ $configspec ] );
	my $task = $view->ReconfigVM_Task( spec => $spec );
	&Vcenter::Task_getStatus( $task );
}


## Return number of VirtualE1000 interfaces
## Parameters:
##  vmname: name of vm
## Returns:
##  count: number of network interfaces

sub count_network_interface {
	my ( $vmname ) =@_;
	my $view = Vim::find_entity_view( view_type => 'VirtualMachine', properties => [ 'name' ], filter => { name => $vmname } );
	if ( !defined( $view ) ) {
		SDK::Error::Entity::NumException->throw( error => 'Could not retrieve VM entity', entity => $vmname, count => '0' );
	}
	my $count =0;
	foreach ( @{ $view->config->hardware->device } ) {
		my $interface = $_;
		if ( $interface->isa( 'VirtualE1000' ) ) {
			$count++;
		}
	}
	return $count;
}

sub count_cdrom {
	my ( $vmname ) =@_;
	my $view = Vim::find_entity_view( view_type => 'VirtualMachine', properties => [ 'name' ], filter => { name => $vmname } );
	if ( !defined( $view ) ) {
		SDK::Error::Entity::NumException->throw( error => 'Could not retrieve VM entity', entity => $vmname, count => '0' );
	}
	my $count =0;
	foreach ( @{ $view->config->hardware->device } ) {
		my $disk = $_;
		if ( $disk->isa( 'VirtualCdrom' ) ) {
			$count++;
		}
	}
	return $count;
}

sub count_disk {
	my ( $vmname ) =@_;
	my $view = Vim::find_entity_view( view_type => 'VirtualMachine', properties => [ 'name' ], filter => { name => $vmname } );
	if ( !defined( $view ) ) {
		SDK::Error::Entity::NumException->throw( error => 'Could not retrieve VM entity', entity => $vmname, count => '0' );
	}
	my $count =0;
	foreach ( @{ $view->config->hardware->device } ) {
		my $disk = $_;
		if ( $disk->isa( 'VirtualDisk' ) ) {
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
	my ( $vmname, $num ) = @_;
	my ( $key, $unitnumber, $controllerkey, $mac ) = &get_network_interface( $vmname, $num );
	my $view = Vim::find_entity_view( view_type => 'VirtualMachine', properties => [ 'name' ], filter => { name => $vmname } );
	if ( !defined( $view ) ) {
		SDK::Error::Entity::NumException->throw( error => 'Could not retrieve VM entity', entity => $vmname, count => '0' );
	}
	my $device = VirtualE1000->new( key => $key );
	my $deviceconfig = VirtualDeviceConfigSpec->new( operation => VirtualDeviceConfigSpecOperation->new( 'remove' ), device => $device );
	my $spec = VirtualMachineConfigSpec->new( deviceChange => [ $deviceconfig ] );
	$view->ReconfigVM_Task( spec => $spec );
}

sub remove_disk {
	my ( $vmname, $num ) = @_;
	my ( $key, $size, $path ) = &get_disk( $vmname, $num );
	my $view = Vim::find_entity_view( view_type => 'VirtualMachine', properties => [ 'name' ], filter => { name => $vmname } );
	if ( !defined( $view ) ) {
		SDK::Error::Entity::NumException->throw( error => 'Could not retrieve VM entity', entity => $vmname, count => '0' );
	}
	my $device = VirtualDisk->new( key => $key, capacityInKB => "1" );
	my $deviceconfig = VirtualDeviceConfigSpec->new( operation => VirtualDeviceConfigSpecOperation->new( 'remove' ), device => $device, fileOperation => VirtualDeviceConfigSpecFileOperation->new( 'destroy' ) );
	my $spec = VirtualMachineConfigSpec->new( deviceChange => [$deviceconfig] );
	$view->ReconfigVM_Task( spec => $spec );
}

sub remove_cdrom {
	my ( $vmname, $num ) = @_;
	my ( $key, $backing, $label ) = &get_cdrom( $vmname, $num );
	my $view = Vim::find_entity_view( view_type => 'VirtualMachine', properties => [ 'name' ], filter => { name => $vmname } );
	if ( !defined( $view ) ) {
		SDK::Error::Entity::NumException->throw( error => 'Could not retrieve VM entity', entity => $vmname, count => '0' );
	}
	my $device = VirtualCdrom->new( key => $key );
	my $deviceconfig = VirtualDeviceConfigSpec->new( operation => VirtualDeviceConfigSpecOperation->new( 'remove' ), device => $device );
	my $spec = VirtualMachineConfigSpec->new( deviceChange => [$deviceconfig] );
	$view->ReconfigVM_Task( spec => $spec );
}



## Return Information about network interface
## Parameters:
##  vmname: name of vm
##  num: number of interface to return information about ( starts at 0 )
## Returns:
##  key: device ID key
##  unitnumber: Unitnumber on controller
##  controllerkey: Key of controller
##  mac: mac address of interface

sub get_network_interface {
	my ( $vmname, $num ) = @_;
	my $view = Vim::find_entity_view( view_type => 'VirtualMachine', properties => [ 'name' ], filter => { name => $vmname } );
	if ( !defined( $view ) ) {
		SDK::Error::Entity::NumException->throw( error => 'Could not retrieve VM entity', entity => $vmname, count => '0' );
	}
	my @keys;
	my @unitnumber;
	my @controllerkey;
	my @mac;
	foreach ( @{ $view->config->hardware->device } ) {
		my $interface = $_;
		if ( !$interface->isa( 'VirtualE1000' ) ) {
			next;
		}
		push( @keys, $interface->key );
		push( @unitnumber, $interface->unitNumber );
		push( @controllerkey, $interface->controllerKey );
		push( @mac, $interface->macAddress );
	}
	return ( $keys[$num], $unitnumber[$num], $controllerkey[$num], $mac[$num] );
}

sub get_disk {
	my ( $vmname, $num ) = @_;
	my $view = Vim::find_entity_view( view_type => 'VirtualMachine', properties => [ 'name' ], filter => { name => $vmname } );
	if ( !defined( $view ) ) {
		SDK::Error::Entity::NumException->throw( error => 'Could not retrieve VM entity', entity => $vmname, count => '0' );
	}
	my @keys;
	my @size;
	my @path;
	foreach ( @{ $view->config->hardware->device } ) {
		my $disk = $_;
		if ( !$disk->isa( 'VirtualDisk' ) ) {
			next;
		}
		push( @keys, $disk->key );
		push( @size, $disk->capacityInKB );
		push( @path, $disk->backing->fileName );
	}
	return ( $keys[$num], $size[$num], $path[$num] );
}

sub get_cdrom {
	my ( $vmname, $num ) = @_;
	my $view = Vim::find_entity_view( view_type => 'VirtualMachine', properties => [ 'name' ], filter => { name => $vmname } );
	if ( !defined( $view ) ) {
		SDK::Error::Entity::NumException->throw( error => 'Could not retrieve VM entity', entity => $vmname, count => '0' );
	}
	my @keys;
	my @backing;
	my @label;
	foreach ( @{ $view->config->hardware->device } ) {
		my $cdrom = $_;
		if ( !$cdrom->isa( 'VirtualCdrom' ) ) {
			next;
		}
		push( @keys, $cdrom->key );
		if ( $cdrom->backing->isa( 'VirtualCdromIsoBackingInfo' ) ) {
			push( @backing, $cdrom->backing->fileName );
		} elsif ( $cdrom->backing->isa( 'VirtualCdromRemotePassthroughBackingInfo' ) ) {
			push( @backing, "Host device" );
		} else {
			push( @backing, "Unknown" );
		}
		push( @label, $cdrom->deviceInfo->label );
	}
	return ( $keys[$num], $backing[$num], $label[$num] );
}

sub get_controller_key {
	my ( $vmname, $devkey ) = @_;
	my $view = Vim::find_entity_view( view_type => 'VirtualMachine', properties => [ 'name' ], filter => { name => $vmname } );
	if ( !defined( $view ) ) {
		SDK::Error::Entity::NumException->throw( error => 'Could not retrieve VM entity', entity => $vmname, count => '0' );
	}
	my $controllerkey;
	foreach ( @{ $view->config->hardware->device } ) {
		my $device = $_;
		if ( $device->key != $devkey ) {
			next;
		}
		$controllerkey = $device->controllerKey;
	}
	return $controllerkey;
}


## Get further information about network interface
## Parameters:
##  vmname: name of vm
##  num: number of interface to return information about ( starts at 0 )
## Returns:
##  network: Network name
##  label: Network interface label

sub get_ext_network_interface {
	my ( $vmname, $num ) = @_;
	my $view = Vim::find_entity_view( view_type => 'VirtualMachine', properties => [ 'name' ], filter => { name => $vmname } );
	if ( !defined( $view ) ) {
		SDK::Error::Entity::NumException->throw( error => 'Could not retrieve VM entity', entity => $vmname, count => '0' );
	}
	my @network;
	my @label;
	foreach ( @{ $view->config->hardware->device } ) {
		my $interface = $_;
		if ( !$interface->isa( 'VirtualE1000' ) ) {
			next;
		}
		push( @network, $interface->backing->deviceName );
		push( @label, $interface->deviceInfo->label );
	}
	return ( $network[$num], $label[$num] );
}

## Changes the attached network to a network interface
## Parameters:
##  vmname: name of vm
##  num: number of interface to do changes
##  network: name of network to change the interface to
## Returns:
##

sub change_network_interface {
	my ( $vmname, $num, $network ) = @_;
	my ( $key, $unitnumber, $controllerkey, $mac ) = &get_network_interface( $vmname, $num );
	my $view = Vim::find_entity_view( view_type => 'VirtualMachine', properties => [ 'name' ], filter => { name => $vmname } );
	if ( !defined( $view ) ) {
		SDK::Error::Entity::NumException->throw( error => 'Could not retrieve VM entity', entity => $vmname, count => '0' );
	}
	my $network_view = Vim::find_entity_view( view_type => 'DistributedVirtualPortgroup', properties => [ 'name', 'key', 'uuid', 'config.distributedVirtualSwitch' ], filter => { name => $network } );
	my $backing;
	if ( !defined( $network_view ) ) {
		$network_view = Vim::find_entity_view( view_type => 'Network', properties => [ 'name' ], filter => { name => $network } );
		if ( !defined( $network ) ) {
			SDK::Error::Entity::NumException->throw( error => 'Could not retrieve VM entity', entity => $network, count => '0' );
		}
		$backing = VirtualEthernetCardNetworkBackingInfo->new( deviceName => $network->name, network => $network );
	} else {
		my $switch = Vim::get_view( mo_ref => $network_view->config->distributedVirtualSwitch );
		my $port = DistributedVirtualSwitchPortConnection->new( portgroupKey => $network_view->key, switchUuid => $switch->uuid );
		$backing = VirtualEthernetCardDistributedVirtualPortBackingInfo->new( port => $port );
	}
	my $device = VirtualE1000->new( connectable => VirtualDeviceConnectInfo->new( startConnected => '1', allowGuestControl => '1', connected => '1' ) , wakeOnLanEnabled => 1, macAddress => $mac , addressType => "Manual", key => $key , backing => $backing, deviceInfo => Description->new( summary => $network_view->name, label => $network_view->name ) );
	my $deviceconfig = VirtualDeviceConfigSpec->new( operation => VirtualDeviceConfigSpecOperation->new( 'edit' ), device => $device );
	my $spec = VirtualMachineConfigSpec->new( deviceChange => [$deviceconfig] );
	my $task = $view->ReconfigVM_Task( spec => $spec );
	&Vcenter::Task_getStatus( $task );
}

## Create switch to hold port groups
## Parameters:
##  name: how to name the switch. Default: ticket
## Returns:
##

sub create_switch {
	my ( $name ) = @_;
	my $root_folder = Vim::find_entity_view( view_type => 'Folder', properties => [ 'name' ], filter => { name => 'network' } );
	if ( !defined( $root_folder ) ) {
		SDK::Error::Entity::NumException->throw( error => 'Could not retrieve Network root folder', entity => 'Network root folder', count => '0' );
	}
	my $host_view = Vim::find_entity_view( view_type => 'HostSystem', properties => [ 'name' ], filter => { name => 'vmware-it1.balabit' } );
	if ( !defined( $host_view ) ) {
		SDK::Error::Entity::NumException->throw( error => 'Could not retrieve Host view', entity => 'vmware-it1.balabit', count => '0' );
	}
	my $hostspec = DistributedVirtualSwitchHostMemberConfigSpec->new( operation => 'add', maxProxySwitchPorts => 99, host => $host_view );
	my $dvsconfigspec = DVSConfigSpec->new( name => $name, maxPorts => 300, description => "DVS for ticket $name", host => [$hostspec] );
	my $spec = DVSCreateSpec->new( configSpec => $dvsconfigspec );
	my $task = $root_folder->CreateDVS_Task( spec => $spec );
	&Vcenter::Task_getStatus( $task );
}

## Deletes switch from esx
## Parameters:
##  name: name of switch
## Returns:
##

sub remove_switch {
	my ( $name ) = @_;
	my $switch = Vim::find_entity_view( view_type => 'DistributedVirtualSwitch', properties => [ 'name' ], filter => { name => $name } );
	if ( !defined( $switch ) ) {
		SDK::Error::Entity::NumException->throw( error => 'Could not retrieve switch view', entity => $name, count => '0' );
	}
	my $task = $switch->Destroy_Task;
	&Vcenter::Task_getStatus( $task );
}

## Create a distributed port group
## Parameters:
##  name: name of dv portgroup
##  switch: name of switch were to add the port group
## Returns:
##

sub create_dvportgroup {
	my ( $name, $switch ) = @_;
	my $switch_view = Vim::find_entity_view( view_type => 'DistributedVirtualSwitch', properties => [ 'name' ], filter => { 'name' => $switch } );
	if ( !defined( $switch_view ) ) {
		&create_switch( $switch );
		$switch_view = Vim::find_entity_view( view_type => 'DistributedVirtualSwitch', properties => [ 'name' ], filter => { 'name' => $switch } );
	}
	my $test = Vim::find_entity_view( view_type => 'DistributedVirtualPortgroup', properties => [ 'name' ], filter => { name => $name } );
	if ( !defined( $test ) ) {
		my $spec = DVPortgroupConfigSpec->new( name => $name, type => 'earlyBinding', numPorts => 20, description => "Port group" );
		my $task = $switch_view->AddDVPortgroup_Task( spec => $spec );
		&Vcenter::Task_getStatus( $task );
	}
}

## Removes dvportgroup , if last, then the switch aswell
## Parameters:
##  name: name of port group to check
## Returns:
##

sub remove_dvportgroup {
	my ( $name ) = @_;
	my $portgroup = Vim::find_entity_view( view_type => 'DistributedVirtualPortgroup', properties => [ 'config.distribuedVirtualSwitch', 'summary.portgroupName' ], filter => { name => $name } );
	if ( !defined( $portgroup ) ) {
		SDK::Error::Entity::NumException->throw( error => 'No DVP found', entity => $name, count => '0' );
	}
	my $parent_switch = $portgroup->config->distributedVirtualSwitch;
	$parent_switch = Vim::get_view( mo_ref => $parent_switch );
	my $count = $parent_switch->summary->portgroupName;
	if ( @$count < 3 ) {
		print "Last portgroup, need to remove DV switch\n";
		&remove_switch( $parent_switch->name );
	} else {
		my $task = $portgroup->Destroy_Task;
		&Vcenter::Task_getStatus( $task );
	}
}

sub dvportgroup_status {
	my ( $name ) = @_;
	my $network = Vim::find_entity_view( view_type => 'Network', properties => [ 'name' ], filter => { 'name' => $name } );
	if ( defined( $network ) ) {
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
	my $networks = Vim::find_entity_views( view_type => 'Network', properties => [ 'name' ] );
	if ( !defined( $networks ) ) {
		SDK::Error::Entity::NumException->throw( error => 'No DVP found', entity => 'DistributedVirtualPortGroup', count => '0' );
	}
	foreach( @$networks ) {
		print "name:'" . $_->name ."'\n";
	}
}

## List all dvportgroups on esx..
## Parameters:
##
## Returns:
##

sub list_dvportgroup {
	my $networks = Vim::find_entity_views( view_type => 'DistributedVirtualPortgroup', properties => [ 'name' ] );
	if ( !defined( $networks ) ) {
		SDK::Error::Entity::NumException->throw( error => 'No DVP found', entity => 'DistributedVirtualPortGroup', count => '0' );
	}
	foreach( @$networks ) {
		print "name:'" . $_->name ."'\n";
	}
}

sub CustomizationAdapterMapping_generator {
	my ( $os ) = @_;
	my @return;
	if ( defined( $Support::template_hash{ $os } ) ) {
		my $source_temp = $Support::template_hash{ $os }{ 'path' };
		$source_temp = &Vcenter::path_to_moref( $source_temp );
		foreach ( @{ $source_temp->config->hardware->device } ) {
			if ( !$_->isa( 'VirtualE1000' ) ) {
				next;
			}
			my $ip = CustomizationDhcpIpGenerator->new( );
			my $adapter = CustomizationIPSettings->new( dnsDomain => 'support.balabit', dnsServerList => [ '10.10.0.1' ], gateway => [ '10.21.255.254' ], subnetMask => '255.255.0.0', ip => $ip, netBIOS => CustomizationNetBIOSMode->new( 'disableNetBIOS' ) );
			my $nicsetting = CustomizationAdapterMapping->new( adapter => $adapter );
			push( @return, $nicsetting );
		}

	} else {
		SDK::Error::Template::Error->throw( error => 'Cannot find template', template => $os );
	}
	return \@return;
}

sub get_scsi_controller {
	my ( $name ) = @_;
	my $view = Vim::find_entity_view( view_type => 'VirtualMachine', properties => [ 'config.hardware.device' ], filter => { name => $name } );
	if ( !defined( $view ) ) {
		SDK::Error::Entity::NumException->throw( error => 'Could not find VM entity', entity => $name, count => '0' );
	}
	my $controller;
	my $num_controller = 0;
	foreach ( @{ $view->config->hardware->device } ) {
		if ( ref( $_ ) =~ /VirtualBusLogicController|VirtualLsiLogicController|VirtualLsiLogicSASController|ParaVirtualSCSIController/ ) {
		$num_controller++;
		$controller = $_;
		}
	}
	if ( $num_controller != 1 ) {
		SDK::Error::Entity::HWError->throw( error => 'Scsi controller count not good', entity => $name, hw => 'SCSI Controller' );
	}
	return $controller;
}

#VirtualIDEController

sub get_free_ide_controller {
	my ( $name ) = @_;
	my $view = Vim::find_entity_view( view_type => 'VirtualMachine', properties => [ 'config.hardware.device' ], filter => { name => $name } );
	if ( !defined( $view ) ) {
		SDK::Error::Entity::NumException->throw( error => 'Could not find VM entity', entity => $name, count => '0' );
	}
	my @controller;
	my $num_controller = 0;
	foreach ( @{ $view->config->hardware->device } ) {
		if ( ref( $_ ) =~ /VirtualIDEController/ ) {
			$num_controller++;
			push( @controller, $_ );
		}
	}
	foreach ( @controller ) {
		if ( defined( $_->device ) ) {
			if ( @{ $_->device } lt 2 ) {
				return $_->key;
			}
		} else {
			return $_->key;
		}
	}
	SDK::Error::Entity::HWError->throw( error => 'Ide Controller Full', entity => $name, hw => 'Ide Controller' );
}

sub get_annotation_key {
	my ( $vmname, $name ) =@_;
	my $view = Vim::find_entity_view( view_type => 'VirtualMachine', properties => [ 'availableField' ], filter => { name => $vmname } );
	if ( !defined( $view ) ) {
		SDK::Error::Entity::NumException->throw( error => 'Could not find VM entity', entity => $vmname, count => '0' );
	}
	foreach ( @{ $view->availableField } ) {
		if ( $_->name eq $name  ) {
			return $_->key;
		}
	}
	return 0;
}

sub change_altername {
	my ( $vmname, $string ) =@_;
	my $view = Vim::find_entity_view( view_type => 'VirtualMachine', properties => [ 'name' ], filter => { name => $vmname } );
	if ( !defined( $view ) ) {
		SDK::Error::Entity::NumException->throw( error => 'Could not find VM entity', entity => $vmname, count => '0' );
	}
	my $sc = Vim::get_service_content( );
	if ( !defined( $sc ) ) {
		SDK::Error::Entity::ServiceContent->throw( error => 'Could not return Service Content' );
	}
	my $custom = Vim::get_view( mo_ref => $sc->customFieldsManager );
	my $key = &get_annotation_key( $vmname, "alternateName" );
	$custom->SetField( entity => $view, key => $key, value => $string )
}

sub get_altername {
	my ( $vmname ) =@_;
	my $view = Vim::find_entity_view( view_type => 'VirtualMachine', properties => [ 'value' ], filter => { name => $vmname } );
	if ( !defined( $view ) ) {
		SDK::Error::Entity::NumException->throw( error => 'Could not find VM entity', entity => $vmname, count => '0' );
	}
	my $key = &get_annotation_key( $vmname, "alternateName" );
	if ( defined( $view->value ) ) {
		foreach ( @{ $view->value } ) {
			if ( $_->key eq $key ) {
				return $_->value;
			}
		}
	}
	return "";
}

sub create_snapshot {
	my ( $vmname, $name, $description ) = @_;
	my $view = Vim::find_entity_view( view_type => 'VirtualMachine', properties => [ 'name' ], filter => { name => $vmname } );
	if ( !defined( $view ) ) {
		SDK::Error::Entity::NumException->throw( error => 'Could not find VM entity', entity => $vmname, count => '0' );
	}
	my $task = $view->CreateSnapshot_Task( name => $name, description => $description, memory => 1, quiesce => 1 );
	&Vcenter::Task_getStatus( $task );
}

sub list_snapshot {
	my ( $vmname ) = @_;
	my $current_snapshot;
	my $view = Vim::find_entity_view( view_type => 'VirtualMachine', filter => { name => $vmname } );
	if ( !defined( $view ) ) {
		SDK::Error::Entity::NumException->throw( error => 'Could not find VM entity', entity => $vmname, count => '0' );
	}
	if ( defined( $view->snapshot ) ) {
		$current_snapshot = $view->snapshot->currentSnapshot->value;
	} else {
		SDK::Error::Entity::Snapshot->throw( error => "No snapshot found by vm $vmname" );
	}
	if ( defined( $view->snapshot ) ) {
		print "Found snapshots listing\n";
		foreach ( @{ $view->snapshot->rootSnapshotList } ) {
			&traverse_snapshot( $_, $current_snapshot );
		}
		return 1;
	} else {
		SDK::Error::Entity::Snapshot->throw( error => "No snapshot found by vm $vmname" );
	}
	return 0;
}

sub remove_snapshot {
	my ( $vmname, $id ) = @_;
	my $view = Vim::find_entity_view( view_type => 'VirtualMachine', properties => [ 'snapshot' ], filter => { name => $vmname } );
	if ( !defined( $view ) ) {
		SDK::Error::Entity::NumException->throw( error => 'Could not find VM entity', entity => $vmname, count => '0' );
	}
	if ( defined( $view->snapshot ) ) {
		foreach ( @{ $view->snapshot->rootSnapshotList } ) {
			my $snapshot = &find_snapshot_by_id( $_, $id );
			if ( defined( $snapshot ) ) {
				print "Found Id removing\n";
				my $moref = Vim::get_view( mo_ref => $snapshot->snapshot );
				my $task = $moref->RemoveSnapshot_Task( removeChildren => 0 );
				&Vcenter::Task_getStatus( $task );
				return 1;
			}
			return 0;
		}
	} else {
		SDK::Error::Entity::Snapshot->throw( error => "No snapshot found by vm $vmname" );
	}
	return 0;
}

sub remove_all_snapshot {
	my ( $vmname ) = @_;
	my $view = Vim::find_entity_view( view_type => 'VirtualMachine', properties => [ 'name' ], filter => { name => $vmname } );
	if ( !defined( $view ) ) {
		SDK::Error::Entity::NumException->throw( error => 'Could not find VM entity', entity => $vmname, count => '0' );
	}
	my $task = $view->RemoveAllSnapshots_Task( consolidate => 1 );
	&Vcenter::Task_getStatus( $task );
	return 1;
}

sub find_snapshot_by_id {
	my ( $snapshot, $id ) = @_;
	my $return;
	if ( $snapshot->id == $id ) {
		return $snapshot;
	} elsif ( defined( $snapshot->childSnapshotList ) ) {
		foreach ( @{ $snapshot->childSnapshotList } ) {
			if ( !defined( $return ) ) {
				$return = &find_snapshot_by_id( $_, $id );
			}
		}
	}
	return $return;
}

sub revert_to_snapshot {
	my ( $vmname, $id ) = @_;
	my $view = Vim::find_entity_view( view_type => 'VirtualMachine', properties => [ 'snapshot' ], filter => { name => $vmname } );
	if ( !defined( $view ) ) {
		SDK::Error::Entity::NumException->throw( error => 'Could not find VM entity', entity => $vmname, count => '0' );
	}
	if ( defined( $view->snapshot ) ) {
		foreach ( @{ $view->snapshot->rootSnapshotList } ) {
			my $snapshot = &find_snapshot_by_id( $_, $id );
			if ( defined( $snapshot ) ) {
				print "Found Id reverting\n";
				my $moref = Vim::get_view( mo_ref => $snapshot->snapshot );
				my $task = $moref->RevertToSnapshot_Task( suppressPowerOn => 1 );
				&Vcenter::Task_getStatus( $task );
				return 1;
			}
		}
	} else {
		SDK::Error::Entity::Snapshot->throw( error => "No snapshot found by vm $vmname" );
	}
	return 0;
}

sub traverse_snapshot {
	my ( $snapshot_moref, $current_snapshot ) = @_;
	if ( $snapshot_moref->snapshot->value eq $current_snapshot ) {
		print "*CUR* ";
	}
	print "ID => '" .$snapshot_moref->id . "', name => '" . $snapshot_moref->name . "', createTime => '" . $snapshot_moref->createTime . "', description => '" . $snapshot_moref->description . "'\n\n";
	if ( defined( $snapshot_moref->{ 'childSnapshotList' } ) ) {
		foreach ( @{ $snapshot_moref->{ 'childSnapshotList' }} ) {
			&traverse_snapshot( $_, $current_snapshot );
		}
	}
	return 0;
}

sub poweron_vm {
	my ( $vmname ) = @_;
	my $view = Vim::find_entity_view( view_type => 'VirtualMachine', properties => [ 'runtime.powerState' ], filter => { name => $vmname } );
	if ( !defined( $view ) ) {
		SDK::Error::Entity::NumException->throw( error => 'Could not find VM entity', entity => $vmname, count => '0' );
	}
	if ( $view->runtime->powerState->val ne "poweredOff" ) {
		print "$vmname already powered on.\n";
		return 0;
	}
	my $task = $view->PowerOnVM_Task;
	&Vcenter::Task_getStatus( $task );
	print "$vmname powered on.\n";
}

sub poweroff_vm {
	my ( $vmname ) = @_;
	my $view = Vim::find_entity_view( view_type => 'VirtualMachine', properties => [ 'runtime.powerState' ], filter => { name => $vmname } );
	if ( !defined( $view ) ) {
		SDK::Error::Entity::NumException->throw( error => 'Could not find VM entity', entity => $vmname, count => '0' );
	}
	if ( $view->runtime->powerState->val eq "poweredOff" ) {
		print "$vmname already powered off.\n";
		return 0;
	}
	my $task = $view->PowerOffVM_Task;
	&Vcenter::Task_getStatus( $task );
	print "$vmname powered off.\n";
}

sub promote_vdisk {
	my ( $vmname ) = @_;
	&poweroff_vm( $vmname );
	my $view = Vim::find_entity_view( view_type => 'VirtualMachine', properties => [ 'name' ], filter => { name => $vmname } );
	if ( !defined( $view ) ) {
		SDK::Error::Entity::NumException->throw( error => 'Could not find VM entity', entity => $vmname, count => '0' );
	}
	my $task = $view->PromoteDisks_Task(unlink=>1);
	&Vcenter::Task_getStatus( $task );
	&move_into_folder( $vmname );
	return 1;
}

sub move_into_folder {
	my ( $vmname ) = @_;
	my ( $ticket, $username, $family, $version, $lang, $arch, $type , $uniq ) = &Misc::vmname_splitter( $vmname );
	&Vcenter::create_folder( $ticket, "vm" );
	my $machine_view = Vim::find_entity_view( view_type => 'VirtualMachine', properties => [ 'name' ], filter => { name => $vmname } );
	if ( !defined( $machine_view ) ) {
		SDK::Error::Entity::NumException->throw( error => 'Cannot find VM entity', entity => $vmname, count => '0' );
	}
	my $folder_view = Vim::find_entity_view( view_type => 'Folder', properties => [ 'name' ], filter => { name => $ticket } );
	if ( !defined( $folder_view ) ) {
		SDK::Error::Entity::NumException->throw( error => 'Could not find Folder entity', entity => $ticket, count => '0' );
	}
	my $task = $folder_view->MoveIntoFolder_Task( list => [ $machine_view ] );
	&Vcenter::Task_getStatus( $task );
}

## Functionality test sub

sub test( ) {
	print "GuestManagement module test sub\n";
}

#### We need to end with success
1
