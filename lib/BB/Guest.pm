package Guest;

use strict;
use warnings;

BEGIN {
    use Exporter;
    our @ISA    = qw( Exporter );
    our @EXPORT = qw( );
}

#tested
sub entity_name_view {
    my ( $name, $type ) = @_;
    &Log::debug("Retrieving entity name view, name=>'$name', type=>'$type'");
    &VCenter::num_check( $name, $type );
    my $view = &Guest::entity_property_view( $name, $type, 'name' );
    return $view;
}

#tested
sub entity_full_view {
    my ( $name, $type ) = @_;
    &Log::debug(
        "Retrieving entity full view sub, name=>'$name', type=>'$type'");
    &VCenter::num_check( $name, $type );
    my $view =
      Vim::find_entity_view( view_type => $type, filter => { name => $name } );
    &Log::dumpobj( "full_view", $view );
    return $view;
}

#tested
sub entity_property_view {
    my ( $name, $type, $property ) = @_;
    &Log::debug(
"Retrieving entity property view sub, name=>'$name', type=>'$type', property=>'$property'"
    );
    &VCenter::num_check( $name, $type );
    my $view = Vim::find_entity_view(
        view_type  => $type,
        properties => [$property],
        filter     => { name => $name }
    );
    &Log::dumpobj( "property_view", $view );
    return $view;
}

sub find_last_snapshot {
    my ($snapshot_view) = @_;
    &Log::dumpobj( "snapshot", $snapshot_view );
    &Log::debug("Starting Guest::find_last_snapshot sub");
##FIXME atgondolni a rekurziot
    foreach (@$snapshot_view) {
        if ( defined( $_->{'childSnapshotList'} ) ) {
            &Guest::find_last_snapshot( $_->{'childSnapshotList'} );
        }
        else {
            &Log::debug( "Found snapshot returning, name=>'" . $_->name . "'" );
            &Log::dumpobj( "return_snapshot", $_ );
            return $_;
        }
    }
}

#tested
sub get_altername {
    my ($vmname) = @_;
    &Log::debug("Starting Guest::get_altername sub, vmname=>'$vmname'");
    my $view =
      &Guest::entity_property_view( $vmname, 'VirtualMachine', 'value' );
    my $key = &Guest::get_annotation_key( $vmname, "alternateName" );
    if ( defined( $view->value ) ) {
        foreach ( @{ $view->value } ) {
            if ( $_->key eq $key ) {
                &Log::debug( "Found altername value=>'" . $_->value . "'" );
                return $_->value;
            }
        }
    }
    &Log::debug("No altername was found, returning empty string");
    return "";
}

#tested
sub change_altername {
    my ( $vmname, $name ) = @_;
    &Log::debug(
        "Starting Guest::change_altername sub, vmname=>'$vmname', name=>'$name'"
    );
    &VCenter::num_check( $vmname, 'VirtualMachine' );
    my $view   = &Guest::entity_name_view( $vmname, 'VirtualMachine' );
    my $sc     = Vim::get_service_content();
    my $custom = Vim::get_view( mo_ref => $sc->customFieldsManager );
    my $key    = &Guest::get_annotation_key( $vmname, "alternateName" );
    $custom->SetField( entity => $view, key => $key, value => $name );
    &Log::debug("Finished changing altername");
    return 1;
}

sub remove_cdrom_iso_spec {
    my ( $vmname, $num ) = @_;
    &Log::debug("Starting Guest::add_cdrom_spec sub");
    &Log::debug("Opts are, vmname=>'$vmname', num=>'$num'");
    my @cdrom_hw = @{ &Guest::get_hw( $vmname, 'VirtualCdrom' ) };
    my $controller =
      &Guest::key2hw( $vmname, $cdrom_hw[$num]->{controllerKey} );
    my $normbacking = VirtualCdromRemotePassthroughBackingInfo->new(
        exclusive  => 0,
        deviceName => ''
    );
    my $device = VirtualCdrom->new(
        backing       => $normbacking,
        key           => $cdrom_hw[$num]->{key},
        controllerKey => $controller->{key}
    );
    my $configspec = VirtualDeviceConfigSpec->new(
        device    => $device,
        operation => VirtualDeviceConfigSpecOperation->new('edit')
    );
    my $spec = VirtualMachineConfigSpec->new( deviceChange => [$configspec] );
    return $spec;
}

sub change_cdrom_iso_spec {
    my ( $vmname, $num, $iso ) = @_;
    &Log::debug("Starting Guest::add_cdrom_spec sub");
    &Log::debug("Opts are, vmname=>'$vmname', num=>'$num', iso=>'$iso'");
    if ( !&VCenter::datastore_file_exists($iso) ) {
        Vcenter::Path->throw(
            error => 'Datastore file could not be found',
            path  => $iso
        );
    }
    my ( $datas, $folder, $image ) = &Misc::filename_splitter($iso);
    my @cdrom_hw = @{ &Guest::get_hw( $vmname, 'VirtualCdrom' ) };
    my $controller =
      &Guest::key2hw( $vmname, $cdrom_hw[$num]->{controllerKey} );
    my $isobacking = VirtualCdromIsoBackingInfo->new( fileName => $iso );
    my $device = VirtualCdrom->new(
        backing       => $isobacking,
        key           => $cdrom_hw[$num]->{key},
        controllerKey => $controller->{key}
    );
    my $configspec = VirtualDeviceConfigSpec->new(
        device    => $device,
        operation => VirtualDeviceConfigSpecOperation->new('edit')
    );
    my $spec = VirtualMachineConfigSpec->new( deviceChange => [$configspec] );
    return $spec;
}

sub change_interface_spec {
    my ( $vmname, $num, $network ) = @_;
    &Log::debug("Starting Guest::change_interface_spec");
    &Log::debug(
        "Opts are, vmname=>'$vmname', num=>'$num', network=>'$network'");
    my @net_hw = @{ &Guest::get_hw( $vmname, 'VirtualEthernetCard' ) };
    my $network_view =
      &Guest::entity_property_view( $network, 'Network', 'name' );
    my $name = $network_view->{name};
    &Log::debug("Name is $name");
    my $backing;

    if ( $network_view->{mo_ref}->{type} eq 'Network' ) {
        &Log::debug("Network is a normal network");
        $backing = VirtualEthernetCardNetworkBackingInfo->new(
            deviceName => $name,
            network    => $network
        );
    }
    elsif ( $network_view->{mo_ref}->{type} eq 'DistributedVirtualPortgroup' ) {
        &Log::debug("Network is a normal DVP");
        $network_view =
          &Guest::entity_full_view( $network, 'DistributedVirtualPortgroup' );
        my $switch = Vim::get_view(
            mo_ref => $network_view->{config}->{distributedVirtualSwitch} );
        my $port = DistributedVirtualSwitchPortConnection->new(
            portgroupKey => $network_view->{key},
            switchUuid   => $switch->{uuid}
        );
        $backing =
          VirtualEthernetCardDistributedVirtualPortBackingInfo->new(
            port => $port );
    }
    else {
        &Log::debug("Unkown network type");

        #FIXME Implement exception
    }
    my $device = VirtualE1000->new(
        connectable => VirtualDeviceConnectInfo->new(
            startConnected    => '1',
            allowGuestControl => '1',
            connected         => '1'
        ),
        wakeOnLanEnabled => 1,
        macAddress       => $net_hw[$num]->{macAddress},
        addressType      => "Manual",
        key              => $net_hw[$num]->{key},
        backing          => $backing,
        deviceInfo       => Description->new( summary => $name, label => $name )
    );
    my $deviceconfig = VirtualDeviceConfigSpec->new(
        operation => VirtualDeviceConfigSpecOperation->new('edit'),
        device    => $device
    );
    my $spec = VirtualMachineConfigSpec->new( deviceChange => [$deviceconfig] );
    &Log::debug("Returning spec from change_interface_spec");
    &Log::dumpobj( 'spec', $spec );
    return $spec;
}

#tested
sub add_cdrom_spec {
    my ($vmname) = @_;
    &Log::debug("Starting Guest::add_cdrom_spec sub, vmname=>'$vmname'");
    my $ide_key      = &get_free_ide_controller->{key};
    my $cdrombacking = VirtualCdromRemotePassthroughBackingInfo->new(
        exclusive  => 0,
        deviceName => ''
    );
    my $cdrom = VirtualCdrom->new(
        key           => -1,
        backing       => $cdrombacking,
        controllerKey => $ide_key
    );
    my $devspec = VirtualDeviceConfigSpec->new(
        operation => VirtualDeviceConfigSpecOperation->new('add'),
        device    => $cdrom,
    );
    my $vmspec = VirtualMachineConfigSpec->new( deviceChange => [$devspec] );
    &Log::debug("Returning config spec");
    &Log::dumpobj( "vmspec", $vmspec );
    return $vmspec;
}

#tested
sub add_interface_spec {
    my ( $vmname, $type ) = @_;
    &Log::debug(
"Starting Guest::add_interface_spec sub, vmname=>'$vmname', type=>'$type'"
    );
    my @net_hw = @{ &Guest::get_hw( $vmname, 'VirtualEthernetCard' ) };
    &VCenter::num_check( "VLAN21", "Network" );
    my $switch  = &Guest::entity_name_view( 'VLAN21', 'Network' );
    my $mac     = &Misc::increment_mac( $net_hw[-1]->{macAddress} );
    my $backing = VirtualEthernetCardNetworkBackingInfo->new(
        deviceName => $switch->name,
        network    => $switch
    );
    my $device;

    if ( $type eq "E1000" ) {
        $device = &Guest::E1000_object( $backing, $mac );
    }
    elsif ( $type eq "Vmxnet" ) {
        $device = &Guest::Vmxnet_object( $backing, $mac );
    }
    else {
        Entity::HWError->throw(
            error  => 'Unimplemented interface type was requested',
            entity => $vmname,
            hw     => $type
        );
    }
    my $deviceconfig = VirtualDeviceConfigSpec->new(
        operation => VirtualDeviceConfigSpecOperation->new('add'),
        device    => $device
    );
    my $vmspec =
      VirtualMachineConfigSpec->new( deviceChange => [$deviceconfig] );
    &Log::debug("Returning config spec");
    &Log::dumpobj( "vmspec", $vmspec );
    return $vmspec;
}

#tested
sub E1000_object {
    my ( $backing, $mac ) = @_;
    &Log::debug("Starting Guest::E1000_object sub, mac=>'$mac'");
    &Log::dumpobj( "backing", $backing );
    my $device = VirtualE1000->new(
        connectable => VirtualDeviceConnectInfo->new(
            startConnected    => '1',
            allowGuestControl => '1',
            connected         => '1'
        ),
        wakeOnLanEnabled => 1,
        macAddress       => $mac,
        addressType      => "Manual",
        key              => -1,
        backing          => $backing
    );
    &Log::debug("Returning E1000 object");
    &Log::dumpobj( "device", $device );
    return $device;
}

#tested
sub Vmxnet_object {
    my ( $backing, $mac ) = @_;
    &Log::debug("Starting Guest::Vmxnet_object sub, mac=>'$mac'");
    &Log::dumpobj( "backing", $backing );
    my $device = VirtualVmxnet->new(
        connectable => VirtualDeviceConnectInfo->new(
            startConnected    => '1',
            allowGuestControl => '1',
            connected         => '1'
        ),
        wakeOnLanEnabled => 1,
        macAddress       => $mac,
        addressType      => "Manual",
        key              => -1,
        backing          => $backing
    );
    &Log::debug("Returning Vmxnet object");
    &Log::dumpobj( "device", $device );
    return $device;
}

#tested
sub add_disk_spec {
    my ( $vmname, $size ) = @_;
    &Log::debug(
        "Starting Guest::add_disk_spec sub, vmname=>'$vmname', size=>'$size'");
    my @disk_hw    = @{ &Guest::get_hw( $vmname, 'VirtualDisk' ) };
    my $scsi_con   = &Guest::get_scsi_controller($vmname);
    my $unitnumber = $disk_hw[-1]->{unitNumber} + 1;

    if ( $unitnumber == 7 ) {
        &Log::debug("Reached Controller ID, incrementing");
        $unitnumber++;
    }
    elsif ( $unitnumber == 15 ) {
        Entity::HWError->throw(
            error  => 'SCSI controller has already 15 disks',
            entity => $vmname,
            hw     => 'SCSI Controller'
        );
    }
    my $inc_path =
      &Misc::increment_disk_name( $disk_hw[-1]->{backing}->{fileName} );
    my $disk_backing_info = VirtualDiskFlatVer2BackingInfo->new(
        fileName        => $inc_path,
        diskMode        => "persistent",
        thinProvisioned => 1
    );
    my $disk = VirtualDisk->new(
        controllerKey => $scsi_con->key,
        unitNumber    => $unitnumber,
        key           => -1,
        backing       => $disk_backing_info,
        capacityInKB  => $size
    );
    my $devspec = VirtualDeviceConfigSpec->new(
        operation     => VirtualDeviceConfigSpecOperation->new('add'),
        device        => $disk,
        fileOperation => VirtualDeviceConfigSpecFileOperation->new('create')
    );
    my $vmspec = VirtualMachineConfigSpec->new( deviceChange => [$devspec] );
    &Log::debug("Returning config spec");
    &Log::dumpobj( "vmspec", $vmspec );
    return $vmspec;
}

#tested
sub get_scsi_controller {
    my ($vmname) = @_;
    &Log::debug("Starting Guest::get_scsi_controller sub, vmname=>'$vmname'");
    my @types = (
        'VirtualBusLogicController',    'VirtualLsiLogicController',
        'VirtualLsiLogicSASController', 'ParaVirtualSCSIController'
    );
    my @controller = ();
    for my $type (@types) {
        &Log::debug1("Looping through $type");
        my @cont = @{ &Guest::get_hw( $vmname, $type ) };
        &Log::dumpobj( "get_hw_return", \@cont );
        if ( scalar(@cont) eq 1 ) {
            &Log::debug("Pushing controller to return array");
            push( @controller, @cont );
        }
    }
    if ( scalar(@controller) != 1 ) {
        Entity::HWError->throw(
            error  => 'Scsi controller count not good',
            entity => $vmname,
            hw     => 'SCSI Controller'
        );
    }
    else {
        &Log::debug("There was one controller as expected");
    }
    &Log::debug("Returning Scsi controller");
    &Log::dumpobj( "controller", \@controller );
    return $controller[0];
}

#tested
sub get_free_ide_controller {
    my ($vmname) = @_;
    &Log::debug(
        "Starting Guest::get_free_ide_controller sub, vmname=>'$vmname'");
    my @controller = @{ &Guest::get_hw( $vmname, 'VirtualIDEController' ) };
    for ( my $i = 0 ; $i < scalar(@controller) ; $i++ ) {
        &Log::dumpobj( "ide_controller", $controller[$i] );
        if ( defined( $controller[$i]->device ) ) {
            &Log::debug("There are devices on controller, checking count");
            if ( @{ $controller[$i]->device } lt 2 ) {
                &Log::debug("There is free space on controller returning key");
                return $controller[$i];
            }
            else {
                &Log::debug("Controller Full");
            }
        }
        else {
            &Log::debug("Controller is empty, returning key");
            return $controller[$i];
        }
    }
    &Log::debug("Found no free ide controller");
    Entity::HWError->throw(
        error  => 'Could not find free ide controller',
        entity => $vmname,
        hw     => 'ide_controller'
    );
}

#tested
sub reconfig_vm {
    my ( $vmname, $spec ) = @_;
    &Log::debug("Starting Guest::reconfig_vm sub, vmname=>'$vmname'");
    &Log::dumpobj( "spec", $spec );
    my $view = &Guest::entity_name_view( $vmname, 'VirtualMachine' );
    my $task = $view->ReconfigVM_Task( spec => $spec );
    &VCenter::Task_Status($task);
    &Log::debug("Finished VM reconfig");
    return 1;
}

#tested
sub get_annotation_key {
    my ( $vmname, $name ) = @_;
    &Log::debug(
"Starting Guest::get_annotation_key sub, vmname=>'$vmname', key=>'$name'"
    );
    &VCenter::num_check( $vmname, 'VirtualMachine' );
    my $view = &Guest::entity_property_view( $vmname, 'VirtualMachine',
        'availableField' );
    foreach ( @{ $view->availableField } ) {
        if ( $_->name eq $name ) {
            &Log::debug( "Found key returning value=>'" . $_->key . "'" );
            return $_->key;
        }
    }
    &Log::debug("No annotation key was found with requested name");
    return 0;
}

#tested
sub network_interfaces {
    my ($vmname) = @_;
    &Log::debug("Starting Guest::network_interfaces sub, vmname=>'$vmname'");
    my %interfaces = ();
    my $view       = &Guest::entity_property_view( $vmname, 'VirtualMachine',
        'config.hardware.device' );
    my $devices = $view->get_property('config.hardware.device');
    for my $device (@$devices) {
        if ( !$device->isa('VirtualEthernetCard') ) {
            &Log::debug("Device is not a network interface, skipping");
            next;
        }
        my $key = $device->key;
        $interfaces{$key} = {};
        if ( $device->isa('VirtualE1000') ) {
            &Log::debug("Interface $key is a VirtualE1000");
            $interfaces{$key}->{type} = 'VirtualE1000';
        }
        elsif ( $device->isa('VirtualVmxnet2') ) {
            &Log::debug("Interface $key is a VirtualVmxnet2");
            $interfaces{$key}->{type} = 'VirtualVmxnet2';
        }
        elsif ( $device->isa('VirtualVmxnet3') ) {
            &Log::debug("Interface $key is a VirtualVmxnet3");
            $interfaces{$key}->{type} = 'VirtualVmxnet3';
        }
        else {
            Entity::HWError->throw(
                error  => 'Interface object is unhandeled',
                entity => $vmname,
                hw     => $key
            );
        }
        $interfaces{$key}->{mac}           = $device->macAddress;
        $interfaces{$key}->{controllerkey} = $device->controllerKey;
        $interfaces{$key}->{unitnumber}    = $device->unitNumber;
        $interfaces{$key}->{label}         = $device->deviceInfo->label;
        $interfaces{$key}->{summary}       = $device->deviceInfo->summary;
        &Log::loghash( "Interface gathered, information, key=>'$key',",
            $interfaces{$key} );
    }
    &Log::debug("Returning interfaces hash");
    return \%interfaces;
}

#tested
sub generate_network_setup {
    my ($os_temp) = @_;
    my @return;
    &Log::debug("Starting Guest::generate_network_sub, os_temp=>'$os_temp'");
    if ( !defined( &Support::get_key_info( 'template', $os_temp ) ) ) {
        Template::Status->throw(
            error    => 'Template does not exists',
            template => $os_temp
        );
    }
    my $os_temp_path = &Support::get_key_value( 'template', $os_temp, 'path' );
    my $os_temp_view =
      &VCenter::moref2view( &VCenter::path2moref($os_temp_path) );
    my %keys = %{ &Guest::network_interfaces( $os_temp_view->name ) };
    my @mac  = &Misc::generate_macs( scalar( keys %keys ) );
    for my $key ( keys %keys ) {
        my $ethernetcard;
        if ( $keys{$key}->{type} eq 'VirtualE1000' ) {
            &Log::debug("Generating setup for a E1000 device");
            $ethernetcard = VirtualE1000->new(
                addressType      => 'Manual',
                macAddress       => pop(@mac),
                wakeOnLanEnabled => 1,
                key              => $key
            );
        }
        elsif ( $keys{$key}->{type} eq 'VirtualVmxnet2' ) {
            &Log::debug("Generating setup for a VirtualVmxnet2");
            $ethernetcard = VirtualVmxnet2->new(
                addressType      => 'Manual',
                macAddress       => pop(@mac),
                wakeOnLanEnabled => 1,
                key              => $key
            );
        }
        elsif ( $keys{$key}->{type} eq 'VirtualVmxnet3' ) {
            &Log::debug("Generating setup for a VirtualVmxnet3");
            $ethernetcard = VirtualVmxnet3->new(
                addressType      => 'Manual',
                macAddress       => pop(@mac),
                wakeOnLanEnabled => 1,
                key              => $key
            );
        }
        else {
            Entity::HWError->throw(
                error  => 'Interface Hash contains unknown type',
                entity => $os_temp,
                hw     => $key
            );
        }
        my $operation        = VirtualDeviceConfigSpecOperation->new('edit');
        my $deviceconfigspec = VirtualDeviceConfigSpec->new(
            device    => $ethernetcard,
            operation => $operation
        );
        push( @return, $deviceconfigspec );
    }
    &Log::debug("Returning array network devices Config Spec");
    return @return;
}

#tested
sub CustomizationAdapterMapping_generator {
    my ($vmname) = @_;
    &Log::debug(
        "Starting Guest::CustomizationAdapterMapping_generator sub, vmname=>'"
          . $vmname
          . "'" );
    my @return;
    for my $key ( keys &Guest::network_interfaces($vmname) ) {
        &Log::debug("Generating $key Adapter mapping");
        my $ip      = CustomizationDhcpIpGenerator->new();
        my $adapter = CustomizationIPSettings->new(
            dnsDomain     => 'support.balabit',
            dnsServerList => ['10.10.0.1'],
            gateway       => ['10.21.255.254'],
            subnetMask    => '255.255.0.0',
            ip            => $ip,
            netBIOS       => CustomizationNetBIOSMode->new('enableNetBIOS')
        );
        my $nicsetting =
          CustomizationAdapterMapping->new( adapter => $adapter );
        push( @return, $nicsetting );
    }
    &Log::debug("Returning array of adapter mappings");
    return @return;
}

#tested
sub get_hw {
    my ( $vmname, $hw ) = @_;
    &Log::debug( "Starting Guest::get_hw sub, vmname=>'"
          . $vmname
          . "', hw=>'"
          . $hw
          . "'" );
    my @hw   = ();
    my $view = &Guest::entity_property_view( $vmname, 'VirtualMachine',
        'config.hardware.device' );
    &Log::debug("Starting loop through hardver");
    my $devices = $view->get_property('config.hardware.device');
    foreach ( @{$devices} ) {

        if ( $_->isa($hw) ) {
            &Log::debug("Found requrested hardver pushing to return");
            push( @hw, $_ );
        }
    }
    &Log::debug( "Returning count=>'" . scalar(@hw) . "'" );
    &Log::dumpobj( $hw, \@hw );
    return \@hw;
}

sub key2hw {
    my ( $vmname, $key ) = @_;
    &Log::debug( "Starting Guest::key2hw sub, vmname=>'"
          . $vmname
          . "', key=>'"
          . $key
          . "'" );
    my $hw;
    my $view = &Guest::entity_property_view( $vmname, 'VirtualMachine',
        'config.hardware.device' );
    &Log::debug("Starting loop through hardver");
    my $devices = $view->get_property('config.hardware.device');
    foreach ( @{$devices} ) {

        if ( $_->{key} eq $key ) {
            &Log::debug("Found requrested hardver pushing to return");
            $hw = $_;
        }
    }
    &Log::debug("Returning requested hw");
    &Log::dumpobj( 'hw', $hw );
    return $hw;
}

#tested
sub poweron {
    my ($vmname) = @_;
    &Log::debug("Starting Guest::poweron sub, vmname=>'$vmname'");
    &VCenter::num_check( $vmname, 'VirtualMachine' );
    my $view =
      &Guest::entity_property_view( $vmname, 'VirtualMachine',
        'runtime.powerState' );
    my $powerstate = $view->get_property('runtime.powerState');
    if ( $powerstate->val ne "poweredOff" ) {
        &Log::warning("Machine is already powered on");
        return 0;
    }
    my $task = $view->PowerOnVM_Task;
    &VCenter::Task_Status($task);
    &Log::debug("Powered on VM");
    return 1;
}

#tested
sub poweroff {
    my ($vmname) = @_;
    &Log::debug("Starting Guest::poweroff sub, vmname=>'$vmname'");
    &VCenter::num_check( $vmname, 'VirtualMachine' );
    my $view =
      &Guest::entity_property_view( $vmname, 'VirtualMachine',
        'runtime.powerState' );
    my $powerstate = $view->get_property('runtime.powerState');
    if ( $powerstate->val eq "poweredOff" ) {
        &Log::warning("Machine is already powered off");
        return 0;
    }
    my $task = $view->PowerOffVM_Task;
    &VCenter::Task_Status($task);
    &Log::debug("Powered off VM");
    return 1;
}

#tested
sub revert_to_snapshot {
    my ( $vmname, $id ) = @_;
    &Log::debug(
        "Starting Guest::revert_to_snapshot sub, vmname=>'$vmname', id=>'$id'\n"
    );
    my $view =
      &Guest::entity_property_view( $vmname, 'VirtualMachine', 'snapshot' );
    if ( !defined( $view->snapshot ) ) {
        Entity::Snapshot->throw(
            error    => "No snapshot found",
            entity   => $vmname,
            snapshot => $id
        );
    }
    foreach ( @{ $view->snapshot->rootSnapshotList } ) {
        my $snapshot = &Guest::find_snapshot_by_id( $_, $id );
        if ( defined($snapshot) ) {
            &Log::debug("Found Id reverting");
            my $moref = Vim::get_view( mo_ref => $snapshot->snapshot );
            my $task = $moref->RevertToSnapshot_Task( suppressPowerOn => 1 );
            &VCenter::Task_Status($task);
            &Log::debug(
"Finishing GuestManagement::revert_to_snapshot sub, return=>'success'"
            );
            return 1;
        }
    }
    &Log::debug("Could not revert to requested id");
    return 0;
}

#tested
sub find_snapshot_by_id {
    my ( $snapshot_view, $id ) = @_;
    &Log::debug( "Starting Guest::find_snapshot_by_id sub, snapshot_view_id=>'"
          . $snapshot_view->id
          . "', id=>'$id'" );
    my $return;
    if ( $snapshot_view->id == $id ) {
        &Log::debug("Found the requested snapshot");
        $return = $snapshot_view;
    }
    elsif ( defined( $snapshot_view->childSnapshotList ) ) {
        foreach ( @{ $snapshot_view->childSnapshotList } ) {
            &Log::debug2("Iterating through a snapshot");
            &Log::dumpobj( "snapshot", $_ );
            if ( !defined($return) ) {
                &Log::debug(
                    "We have not found the required snapshot searching");
                $return = &Guest::find_snapshot_by_id( $_, $id );
            }
        }
    }
    &Log::debug("Returning snapshot");
    &Log::dumpobj( "returning snapshot", $return );
    return $return;
}

#tested
sub create_snapshot {
    my ( $vmname, $snap_name, $desc ) = @_;
    &Log::debug( "Starting Guest::create_snapshot sub, vmname=>'"
          . $vmname
          . "', snap_name=>'"
          . $snap_name
          . "', desc=>'"
          . $desc
          . "'" );
    my $view = &Guest::entity_name_view( $vmname, 'VirtualMachine' );
    my $task = $view->CreateSnapshot_Task(
        name        => $snap_name,
        description => $desc,
        memory      => 1,
        quiesce     => 1
    );
    &VCenter::Task_Status($task);
    &Log::debug("Finished create_snapshot sub");
    return 1;
}

#tested
sub remove_all_snapshots {
    my ($vmname) = @_;
    &Log::debug("Starting Guest::remove_all_snapshot sub, vmname=>'$vmname'");
    my $view =
      &Guest::entity_property_view( $vmname, 'VirtualMachine', 'snapshot' );
    if ( !defined( $view->snapshot ) ) {
        Entity::Snapshot->throw(
            error    => "Entity has no snapshots defined",
            entity   => $vmname,
            snapshot => 0
        );
    }
    my $task = $view->RemoveAllSnapshots_Task( consolidate => 1 );
    &Log::dumpobj( "task", $task );
    &VCenter::Task_Status($task);
    &Log::debug("Finished removing all snapshot");
    return 1;
}

#tested
sub remove_snapshot {
    my ( $vmname, $id ) = @_;
    &Log::debug(
        "Starting Guest::remove_snapshot sub, vmname=>'$vmname', id=>'$id'");
    my $view =
      &Guest::entity_property_view( $vmname, 'VirtualMachine', 'snapshot' );
    if ( !defined( $view->snapshot ) ) {
        Entity::Snapshot->throw(
            error    => "Entity has no snapshots defined",
            entity   => $vmname,
            snapshot => 0
        );
    }
    else {
        foreach ( @{ $view->snapshot->rootSnapshotList } ) {
            &Log::dumpobj( "snapshot", $_ );
            my $snapshot = &Guest::find_snapshot_by_id( $_, $id );
            if ( defined($snapshot) ) {
                my $view = &VCenter::moref2view( $snapshot->snapshot );
                &Log::dumpobj( "view", $view );
                my $task = $view->RemoveSnapshot_Task( removeChildren => 0 );
                &Log::dumpobj( "task", $task );
                &VCenter::Task_Status($task);
                &Log::debug("Finished removing snapshot");
                return 1;
            }
            else {
                &Log::debug("Requested snapshot is not in this tree");
            }
        }
        &Log::debug("Finished Looping through the snapshots");
    }
    &Log::debug("Could not find requested snapshot id to remove");
    return 0;
}

sub remove_hw {
    my ( $vmname, $hw ) = @_;
    &Log::debug("Starting Guest::remove_hw sub");
    &Log::dumpobj( "hw", $hw );
    my $deviceconfig;
    if ( $hw->isa('VirtualDisk') ) {
        $deviceconfig = VirtualDeviceConfigSpec->new(
            operation => VirtualDeviceConfigSpecOperation->new('remove'),
            device    => $hw,
            fileOperation =>
              VirtualDeviceConfigSpecFileOperation->new('destroy')
        );
    }
    else {
        $deviceconfig = VirtualDeviceConfigSpec->new(
            operation => VirtualDeviceConfigSpecOperation->new('remove'),
            device    => $hw
        );
    }
    my $vmspec =
      VirtualMachineConfigSpec->new( deviceChange => [$deviceconfig] );
    &Guest::reconfig_vm( $vmname, $vmspec );
    return 1;
}

sub promote {
    my ($vmname) = @_;
    &Log::debug("Starting Guest::promote sub");
    &Log::debug("Opts are, vmname=>'$vmname'");
    &Guest::poweroff($vmname);
    my $view = &Guest::entity_name_view( $vmname, 'VirtualMachine' );
    my $task = $view->PromoteDisks_Task( unlink => 1 );
    &VCenter::Task_Status($task);
    my $splitted = &Misc::vmname_splitter($vmname);
    if ( !&VCenter::exists_entity( $splitted->{ticket}, 'Folder' ) ) {
        &VCenter::create_folder( $splitted->{ticket}, 'vm' );
    }
    &VCenter::move_into_folder($vmname, $splitted->{ticket});
    &Log::debug("Finished Guest::promote sub");
    return 1;
}

#tested
sub list_snapshot {
    my ($vmname) = @_;
    &Log::debug("Starting Guest::list_snapshot sub, vmname=>'$vmname'");
    my $view =
      &Guest::entity_property_view( $vmname, 'VirtualMachine', 'snapshot' );
    if (   !defined( $view->snapshot )
        or !defined( $view->snapshot->currentSnapshot ) )
    {
        Entity::Snapshot->throw(
            error    => "Entity has no snapshots defined",
            entity   => $vmname,
            snapshot => 0
        );
    }
    my $current_snapshot = $view->snapshot->currentSnapshot->value;
    &Log::debug1("My current snapshot is: $current_snapshot");
    foreach ( @{ $view->snapshot->rootSnapshotList } ) {
        &Log::debug("Traversing snapshot");
        &Guest::traverse_snapshot( $_, $current_snapshot );
    }
    &Log::debug("Finished listing snapshot");
    return 1;
}

#tested
sub traverse_snapshot {
    my ( $snapshot_moref, $current_snapshot ) = @_;
    &Log::debug(
            "Starting Guest::traverse_snapshot sub, current_snapshot=>'"
          . $current_snapshot
          . "', snapshot_moref_name=>'"
          . $snapshot_moref->name
          . "'" );
    &Log::dumpobj( "snapshot_moref", $snapshot_moref );
    my $current = "";
    if ( $snapshot_moref->snapshot->value eq $current_snapshot ) {
        &Log::debug("Found current active snapshot");
        $current = "*CUR* ";
    }
    print $current
      . "ID => '"
      . $snapshot_moref->id
      . "', name => '"
      . $snapshot_moref->name
      . "', createTime => '"
      . $snapshot_moref->createTime
      . "', description => '"
      . $snapshot_moref->description . "'\n";
    if ( defined( $snapshot_moref->{'childSnapshotList'} ) ) {
        &Log::debug("Found Child snapshot, traversing");
        foreach ( @{ $snapshot_moref->{'childSnapshotList'} } ) {
            &Log::debug("Iterating through branch");
            &Log::dumpobj( "childsnapshot", $_ );
            &Guest::traverse_snapshot( $_, $current_snapshot );
        }
    }
    &Log::debug("Finished traverse_snapshot sub");
    return 1;
}

sub run_command {
    my ($info) = @_;
    &Log::debug("Starting Guest::run_command sub");
    &Log::loghash( "Info options, ", $info );
    my $view       = &Guest::entity_name_view( $info->{vmname} );
    my $guestCreds = &Guest::guest_cred(
        $info->{vmname},
        $info->{guestusername},
        $info->{guestpassword}
    );
    my $guestProcMan  = &VCenter::get_manager("processManager");
    my $guestProgSpec = GuestProgramSpec->new(
        workingDirectory => $info->{workdir},
        programPath      => $info->{prog},
        arguments        => $info->{prog_arg},
        envVariables     => [ $info->{env} ]
    );
    my $pid = $guestProcMan->StartProgramInGuest(
        vm   => $view,
        auth => $guestCreds,
        spec => $guestProgSpec
    );
    &Log::debug("Returning pid $pid");
    return $pid;
}

sub transfer_to_guest {
    my ($info) = @_;
    &Log::debug("Starting Guest::transfer_to_guest sub");
    &Log::loghash( "Info options, ", $info );
    my $view       = &Guest::entity_name_view( $info->{vmname} );
    my $guestCreds = &Guest::guest_cred(
        $info->{vmname},
        $info->{guestusername},
        $info->{guestpassword}
    );
    my $filemanager = &VCenter::get_manager("fileManager");
    my $fileattr    = GuestFileAttributes->new();
    my $size        = -s $info->{path};
    my $transferinfo;
    eval {
        $transferinfo = $filemanager->InitiateFileTransferToGuest(
            vm             => $view,
            auth           => $guestCreds,
            guestFilePath  => $info->{dest},
            fileAttributes => $fileattr,
            fileSize       => $size,
            overwrite      => $info->{overwrite}
        );
    };

    if ($@) {
        Entity::TransferError->throw(
            error    => 'Could not retrieve Transfer information',
            entity   => $info->{vmname},
            filename => $info->{dest}
        );
    }
    print "Information about file:'" . $info->{path} . "'\n";
    print "Size of file: $size bytes";
    my $ua = LWP::UserAgent->new();
    $ua->ssl_opts( verify_hostname => 0 );
    open( my $fh, "<", "$info->{path}" );
    my $content = do { local $/; <$fh> };
    my $req = $ua->put( $transferinfo, Content => $content );

    if ( $req->is_success() ) {
        &Log::debug( "OK: ", $req->content );
    }
    else {
        Entity::TransferError->throw( error => $req->as_string );
    }
    &Log::debug("Returning success");
    return 1;
}

sub transfer_from_guest {
    my ($info) = @_;
    &Log::debug("Starting Guest::transfer_from_guest sub");
    &Log::loghash( "Info options, ", $info );
    my $view = &Guest::entity_name_view( $info->{vmname}, 'VirtualMachine' );
    my $guestCreds = &Guest::guest_cred(
        $info->{vmname},
        $info->{guestusername},
        $info->{guestpassword}
    );
    my $filemanager = &VCenter::get_manager("fileManager");
    my $transferinfo;
    eval {
        $transferinfo = $filemanager->InitiateFileTransferFromGuest(
            vm            => $view,
            auth          => $guestCreds,
            guestFilePath => $info->{path}
        );
    };

    if ($@) {
        Entity::TransferError->throw(
            error    => 'Could not retrieve Transfer information',
            entity   => $info->{vmname},
            filename => $info->{source}
        );
    }
    print "Information about file: $info->{path} \n";
    print "Size: " . $transferinfo->size . " bytes\n";
    print "modification Time: "
      . $transferinfo->attributes->modificationTime
      . " and access Time : "
      . $transferinfo->attributes->accessTime . "\n";
    if ( !defined( $info->{dest} ) ) {
        my $basename = basename( $info->{path} );
        my $content  = get( $transferinfo->url );
        open( my $fh, ">", "/tmp/$basename" );
        print $fh "$content";
        close($fh);
    }
    else {
        &Log::debug( "Downloading file to: '" . $info->{dest} . "'" );
        my $status = getstore( $transferinfo->url, $info->{dest} );
    }
    &Log::debug("Returning success");
    return 1;
}

sub guest_cred {
    my ( $vmname, $guestusername, $guestpassword ) = @_;
    &Log::debug("Starting Guest::guest_cred sub");
    &Log::debug(
"Opts are, vmname=>'$vmname', guestusername=>'$guestusername', guestpassword=>'$guestpassword'"
    );
    my $authMgr   = &VCenter::get_manager("authManager");
    my $guestAuth = NamePasswordAuthentication->new(
        username           => $guestusername,
        password           => $guestpassword,
        interactiveSession => 'false'
    );
    my $view = &Guest::entity_name_view( $vmname, 'VirtualMachine' );
    eval {
        $authMgr->ValidateCredentialsInGuest( vm => $view, auth => $guestAuth );
    };

    if ($@) {
        Entity::Auth->throw(
            error    => 'Could not aquire Guest authentication object',
            entity   => $vmname,
            username => $guestusername,
            password => $guestpassword
        );
    }
    &Log::debug("Returning guestAuth");
    &Log::dumpobj( "guestauth", $guestAuth );
    return $guestAuth;
}

1
__END__
