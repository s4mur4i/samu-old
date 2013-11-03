package Guest;

use strict;
use warnings;

=pod

=head1 Guest.pm

Subroutines from BB/Guest.pm

=cut

BEGIN {
    use Exporter;
    our @ISA    = qw( Exporter );
    our @EXPORT = qw( );
}

=pod

=head2 entity_name_view

=head3 PURPOSE

Returns a managed object containing the requested entities name hash

=head3 PARAMETERS

=over

=item name

Name of the requested entity

=item type

Type of the requested entity

=back

=head3 RETURNS

Managed object with name property

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

=head3 TEST COVERAGE

If exception is thrown if object with 0 count is requested

=cut

sub entity_name_view {
    my ( $name, $type ) = @_;
    &Log::debug("Starting Guest::entity_name_view sub");
    &Log::debug1("Opts are: name=>'$name', type=>'$type'");
    my $view = &Guest::entity_property_view( $name, $type, 'name' );
    &Log::dumpobj( "view", $view );
    &Log::debug("Finishing Guest::entity_name_view sub");
    return $view;
}

=pod

=head2 entity_full_view

=head3 PURPOSE

Returns a managed object containing the requested entities full hash

=head3 PARAMETERS

=over

=item name

Name of requested entity

=item type

Type of requested entity

=back

=head3 RETURNS

Managed object with all property

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

=head3 TEST COVERAGE

If exception is thrown if object with 0 count is requested

=cut

sub entity_full_view {
    my ( $name, $type ) = @_;
    &Log::debug("Starting Guest::entity_full_view sub");
    &Log::debug1("Opts are: name=>'$name', type=>'$type'");
    &VCenter::num_check( $name, $type );
    my $view =
      Vim::find_entity_view( view_type => $type, filter => { name => $name } );
    &Log::dumpobj( "full_view", $view );
    &Log::debug("Finishing Guest::entity_full_view sub");
    return $view;
}

=pod

=head2 entity_property_view

=head3 PURPOSE

Returns a managed object containing the requested entities property hash

=head3 PARAMETERS

=over

=item name

Name of requested entity

=item type

Type of requested entity

=back

=head3 RETURNS

Managed object with requested property

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

=head3 TEST COVERAGE

If exception is thrown if object with 0 count is requested

=cut

sub entity_property_view {
    my ( $name, $type, $property ) = @_;
    &Log::debug("Starting Guest::entity_property_view sub");
    &Log::debug1(
        "Opts are: name=>'$name', type=>'$type', property=>'$property'");
    &VCenter::num_check( $name, $type );
    my $view = Vim::find_entity_view(
        view_type  => $type,
        properties => [$property],
        filter     => { name => $name }
    );
    &Log::dumpobj( "property_view", $view );
    &Log::debug("Finishing Guest::entity_property_view sub");
    return $view;
}

=pod

=head2 find_last_snapshot

=head3 PURPOSE

Retrieve last snapshot

=head3 PARAMETERS

=over

=item snapshot_view

Rootsnapshotlist hash

=back

=head3 RETURNS

Last rootsnapshot is returned

=head3 DESCRIPTION

Multi level snapshots are not supported since it is fubar. Snapshots should be used with care, and should
not be used with multi level setup

=head3 THROWS

=head3 COMMENTS

=head3 TEST COVERAGE

=cut

sub find_last_snapshot {
    my ($snapshot_view) = @_;
    &Log::debug("Starting Guest::find_last_snapshot sub");
    &Log::dumpobj( "snapshot", $snapshot_view );
    foreach (@$snapshot_view) {
        if ( defined( $_->{'childSnapshotList'} ) ) {
            &Guest::find_last_snapshot( $_->{'childSnapshotList'} );
        }
        else {
            &Log::debug("Finishing Guest::find_last_snapshot sub");
            &Log::dumpobj( "return_snapshot", $_ );
            return $_;
        }
    }
}

=pod

=head2 get_altername

=head3 PURPOSE

Retrieves the altername of an entity

=head3 PARAMETERS

=over

=item vmname

Name of virtual machine

=back

=head3 RETURNS

Altername or empty string

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

=head3 TEST COVERAGE

Exception is thrown if unknown vm is requested

=cut

sub get_altername {
    my ($vmname) = @_;
    &Log::debug("Starting Guest::get_altername sub");
    &Log::debug1("Opts are: vmname=>'$vmname'");
    my $view =
      &Guest::entity_property_view( $vmname, 'VirtualMachine', 'value' );
    my $key = &Guest::get_annotation_key( $vmname, "alternateName" );
    my $altername = "";
    if ( defined( $view->value ) ) {
        foreach ( @{ $view->value } ) {
            if ( $_->key eq $key ) {
                &Log::debug( "Found altername value=>'" . $_->value . "'" );
                $altername = $_->value;
            }
        }
    }
    &Log::debug("Returning=>'$altername'");
    &Log::debug("Finishing Guest::get_altername sub");
    return $altername;
}

=pod

=head2 change_altername

=head3 PURPOSE

Changes the altername of a virtual machine

=head3 PARAMETERS

=over

=item vmname

Name of Virtual machine

=item name

Name of alternate name

=back

=head3 RETURNS

Returns true on success

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

=head3 TEST COVERAGE

=cut

sub change_altername {
    my ( $vmname, $name ) = @_;
    &Log::debug("Starting Guest::change_altername sub");
    &Log::debug1("Opts are: vmname=>'$vmname', name=>'$name'");
    my $view   = &Guest::entity_name_view( $vmname, 'VirtualMachine' );
    my $custom = &VCenter::get_manager("customFieldsManager");
    my $key    = &Guest::get_annotation_key( $vmname, "alternateName" );
    $custom->SetField( entity => $view, key => $key, value => $name );
    &Log::debug("Finishing Guest::change_altername sub");
    return 1;
}

=pod

=head2 remove_cdrom_iso_spec

=head3 PURPOSE

Creates a spec for removing a cdrom iso

=head3 PARAMETERS

=over

=item vmname

Name of virtual machine

=item num

Number of cdrom

=back

=head3 RETURNS

A spec for removing cdrom iso

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

=head3 TEST COVERAGE

=cut

sub remove_cdrom_iso_spec {
    my ( $vmname, $num ) = @_;
    &Log::debug("Starting Guest::add_cdrom_spec sub");
    &Log::debug("Opts are: vmname=>'$vmname', num=>'$num'");
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
    &Log::dumpobj( "spec", $spec );
    &Log::debug("Finishing Guest::remove_cdrom_iso_spec sub");
    return $spec;
}

=pod

=head2 change_cdrom_iso_spec

=head3 PURPOSE

Returns a spec for changing an iso backend

=head3 PARAMETERS

=over

=item vmname

Name of Virtual Machine

=item num

Number of cdrom

=item iso

Datastore iso path

=back

=head3 RETURNS

A spec for changing the iso of a cdrom

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

=head3 TEST COVERAGE

=cut

sub change_cdrom_iso_spec {
    my ( $vmname, $num, $iso ) = @_;
    &Log::debug("Starting Guest::change_cdrom_iso_spec sub");
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
    &Log::dumpobj( "spec", $spec );
    &Log::debug("Finishing Guest::change_cdrom_iso_spec sub");
    return $spec;
}

=pod

=head2 change_interface_spec

=head3 PURPOSE

Returns a network interface change spec

=head3 PARAMETERS

=over

=item vmname

Nanme of Virtual Machine

=item num

Number of interface

=item network

Name of requested network

=back

=head3 RETURNS

A spec for changing the interface

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

=head3 TEST COVERAGE

=cut

sub change_interface_spec {
    my ( $vmname, $num, $network ) = @_;
    &Log::debug("Starting Guest::change_interface_spec");
    &Log::debug(
        "Opts are: vmname=>'$vmname', num=>'$num', network=>'$network'");
    my @net_hw = @{ &Guest::get_hw( $vmname, 'VirtualEthernetCard' ) };

    # We also hve to add the first one that is indexed 0
    if ( $num + 1 > scalar(@net_hw) ) {
        Entity::HWError->throw(
            error  => 'Unknown Interface count',
            entity => $vmname,
            hw     => scalar(@net_hw)
        );
    }
    my $network_view =
      &Guest::entity_property_view( $network, 'Network', 'name' );
    my $name = $network_view->{name};
    my $backing;
    &Log::dumpobj( "network_hw", $net_hw[$num] );
    if ( $network_view->{mo_ref}->{type} eq 'Network' ) {
        &Log::debug("Network is a normal network");
        $backing = VirtualEthernetCardNetworkBackingInfo->new(
            deviceName => $name,
            network    => $network_view
        );
    }
    elsif ( $network_view->{mo_ref}->{type} eq 'DistributedVirtualPortgroup' ) {
        &Log::debug("Network is a normal DVP");
        $network_view =
          &Guest::entity_full_view( $network, 'DistributedVirtualPortgroup' );
        my $switch =
          &VCenter::moref2view(
            $network_view->{config}->{distributedVirtualSwitch} );
        my $port = DistributedVirtualSwitchPortConnection->new(
            portgroupKey => $network_view->{key},
            switchUuid   => $switch->{uuid}
        );
        $backing =
          VirtualEthernetCardDistributedVirtualPortBackingInfo->new(
            port => $port );
    }
    else {
        Entity::HWError->throw(
            error  => 'Unknown Network type',
            entity => $vmname,
            hw     => $network_view->{mo_ref}->{type}
        );
    }
    my $device;
    if ( $net_hw[$num]->isa('VirtualE1000') ) {
        $device = VirtualE1000->new(
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
            deviceInfo => Description->new( summary => $name, label => $name )
        );
    }
    elsif ( $net_hw[$num]->isa('VirtualVmxnet3') ) {
        $device = VirtualVmxnet3->new(
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
            deviceInfo => Description->new( summary => $name, label => $name )
        );
    }
    elsif ( $net_hw[$num]->isa('VirtualVmxnet2') ) {
        $device = VirtualVmxnet2->new(
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
            deviceInfo => Description->new( summary => $name, label => $name )
        );
    }
    else {
        Entity::HWError->throw(
            error  => 'Interface object is unhandeled',
            entity => $vmname,
            hw     => $num
        );
    }
    my $deviceconfig = VirtualDeviceConfigSpec->new(
        operation => VirtualDeviceConfigSpecOperation->new('edit'),
        device    => $device
    );
    my $spec = VirtualMachineConfigSpec->new( deviceChange => [$deviceconfig] );
    &Log::debug("Finishing Guest::change_interface_spec sub");
    &Log::dumpobj( 'spec', $spec );
    return $spec;
}

=pod

=head2 add_cdrom_spec

=head3 PURPOSE

Returns a spec for adding a new cdrom

=head3 PARAMETERS

=over

=item vmname

Name of Virtual Machine

=back

=head3 RETURNS

A spec for adding a cdrom

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

=head3 TEST COVERAGE

=cut

sub add_cdrom_spec {
    my ($vmname) = @_;
    &Log::debug("Starting Guest::add_cdrom_spec sub");
    &Log::debug1("Opts are: vmname=>'$vmname'");
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
    &Log::debug("Finishing Gueset::add_cdrom_spec sub");
    &Log::dumpobj( "vmspec", $vmspec );
    return $vmspec;
}

=pod

=head2 add_interface_spec

=head3 PURPOSE

Returns a spec for adding interfaces

=head3 PARAMETERS

=over

=item vmname

Name of Virtual Machine

=item type

Type of interface to add

=back

=head3 RETURNS

A spec for adding an interface

=head3 DESCRIPTION

Default network used is VLAN21

=head3 THROWS

=head3 COMMENTS

=head3 TEST COVERAGE

=cut

sub add_interface_spec {
    my ( $vmname, $type ) = @_;
    &Log::debug("Starting Guest::add_interface_spec sub");
    &Log::debug1("Opts are: vmname=>'$vmname', type=>'$type'");
    my @net_hw = @{ &Guest::get_hw( $vmname, 'VirtualEthernetCard' ) };
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
    my $spec = VirtualMachineConfigSpec->new( deviceChange => [$deviceconfig] );
    &Log::debug("Finishing Guest::add_interface_spec sub");
    &Log::dumpobj( "spec", $spec );
    return $spec;
}

=pod

=head2 E1000_object

=head3 PURPOSE

Returns a E1000 object

=head3 PARAMETERS

=over

=item backing

A managed object for backing information

=item mac

The requested mac address

=back

=head3 RETURNS

A VirtualE1000 managed object

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

=head3 TEST COVERAGE

=cut

sub E1000_object {
    my ( $backing, $mac ) = @_;
    &Log::debug("Starting Guest::E1000_object sub");
    &Log::debug("Opts are: mac=>'$mac'");
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
    &Log::debug("Finishing Guest::E1000_object sub");
    &Log::dumpobj( "device", $device );
    return $device;
}

=pod

=head2 Vmxnet_object

=head3 PURPOSE

Returns a Vmxnet object

=head3 PARAMETERS

=over

=item backing

A managed object for backing information

=item mac

Requested mac address

=back

=head3 RETURNS

A VirtualVmxnet object

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

=head3 TEST COVERAGE

=cut

sub Vmxnet_object {
    my ( $backing, $mac ) = @_;
    &Log::debug("Starting Guest::Vmxnet_object sub");
    &Log::debug1("Opts are: mac=>'$mac'");
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
    &Log::debug("Finishing Guest::Vmxnet_object sub");
    &Log::dumpobj( "device", $device );
    return $device;
}

=pod

=head2 add_disk_spec

=head3 PURPOSE

Returns a spec for adding a harddisk

=head3 PARAMETERS

=over

=item vmname

Name of Virtual Machine

=item size

Size of requested disk

=back

=head3 RETURNS

A spec for adding a disk

=head3 DESCRIPTION

Disk is a thin provisioned disk.

=head3 THROWS

=head3 COMMENTS

=head3 TEST COVERAGE

=cut

sub add_disk_spec {
    my ( $vmname, $size ) = @_;
    &Log::debug("Starting Guest::add_disk_spec sub");
    &Log::debug1("Opts are: vmname=>'$vmname', size=>'$size'");
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
    my $spec = VirtualMachineConfigSpec->new( deviceChange => [$devspec] );
    &Log::debug("Finishing Guest::add_disk_spec sub");
    &Log::dumpobj( "spec", $spec );
    return $spec;
}

=pod

=head2 get_scsi_controller

=head3 PURPOSE

Returns the scsi controllers attributes

=head3 PARAMETERS

=over

=item vmname

Name of Virtual Machine

=back

=head3 RETURNS

Managed object of the Scsi controller

=head3 DESCRIPTION

Virtual Machines should have only only 1 type of scsi controller, of there are multiple we throw an exception

=head3 THROWS

Entity::HWError if there are multiple scsi controllers

=head3 COMMENTS

=head3 TEST COVERAGE

=cut

sub get_scsi_controller {
    my ($vmname) = @_;
    &Log::debug("Starting Guest::get_scsi_controller sub");
    &Log::debug1("Opts are: vmname=>'$vmname'");
    my @types = (
        'VirtualBusLogicController',    'VirtualLsiLogicController',
        'VirtualLsiLogicSASController', 'ParaVirtualSCSIController'
    );
    my @controller = ();
    for my $type (@types) {
        &Log::debug1("Looping through $type");
        my @cont = @{ &Guest::get_hw( $vmname, $type ) };
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
    &Log::debug("Finishing Guest::get_scsi_controller sub");
    &Log::dumpobj( "controller", $controller[0] );
    return $controller[0];
}

=pod

=head2 get_free_ide_controller

=head3 PURPOSE

Returns the first free ide controller

=head3 PARAMETERS

=over

=item vmname

Name of virtual machine

=back

=head3 RETURNS

Ide controller managed object

=head3 DESCRIPTION

=head3 THROWS

Entity::HWError if no free ide controllers found

=head3 COMMENTS

=head3 TEST COVERAGE

=cut

sub get_free_ide_controller {
    my ($vmname) = @_;
    &Log::debug("Starting Guest::get_free_ide_controller sub");
    &Log::debug("Opts are: vmname=>'$vmname'");
    my @controller = @{ &Guest::get_hw( $vmname, 'VirtualIDEController' ) };
    for ( my $i = 0 ; $i < scalar(@controller) ; $i++ ) {
        &Log::dumpobj( "ide_controller", $controller[$i] );
        my $ret;
        if ( defined( $controller[$i]->device ) ) {
            &Log::debug("There are devices on controller, checking count");
            if ( @{ $controller[$i]->device } lt 2 ) {
                &Log::debug("There is free space on controller returning key");
                $ret = $controller[$i];
            }
            else {
                &Log::debug("Controller Full");
                next;
            }
        }
        else {
            &Log::debug("Controller is empty, returning key");
            $ret = $controller[$i];
        }
        if ($ret) {
            &Log::debug("Finishing Guest::get_free_ide_controller sub");
            &Log::dumpobj( "controller_ret", $ret );
            return $ret;
        }
    }
    Entity::HWError->throw(
        error  => 'Could not find free ide controller',
        entity => $vmname,
        hw     => 'ide_controller'
    );
}

=pod

=head2 reconfig_vm

=head3 PURPOSE

Runs a reconfigvm task with requested spec

=head3 PARAMETERS

=over

=item vmname

Name of virtual machine

=item spec

A VirtualMachineConfigSpec for reconfiguring the vm

=back

=head3 RETURNS

True on success

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

=head3 TEST COVERAGE

=cut

sub reconfig_vm {
    my ( $vmname, $spec ) = @_;
    &Log::debug("Starting Guest::reconfig_vm sub");
    &Log::debug1("Opts are: vmname=>'$vmname'");
    &Log::dumpobj( "spec", $spec );
    my $view = &Guest::entity_name_view( $vmname, 'VirtualMachine' );
    my $task = $view->ReconfigVM_Task( spec => $spec );
    &VCenter::Task_Status($task);
    &Log::debug("Finishing Guest::reconfig_vm sub");
    return 1;
}

=pod

=head2 get_annotation_key

=head3 PURPOSE

Returns a key of a customfield

=head3 PARAMETERS

=over

=item vmname

Name of Virtual Machine

=item name

Name of Customfield

=back

=head3 RETURNS

The key number if found

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

=head3 TEST COVERAGE

Exception is thrown if unknown vm is requested
If unkown key is requested then 0 is returned

=cut

sub get_annotation_key {
    my ( $vmname, $name ) = @_;
    &Log::debug("Starting Guest::get_annotation_key sub");
    &Log::debug1("Opts are: vmname=>'$vmname', key=>'$name'");
    my $view = &Guest::entity_property_view( $vmname, 'VirtualMachine',
        'availableField' );
    my $key = 0;
    foreach ( @{ $view->availableField } ) {
        &Log::dumpobj( "customfield", $_ );
        if ( $_->name eq $name ) {
            &Log::debug( "Found key value=>'" . $_->key . "'" );
            $key = $_->key;
        }
    }
    &Log::debug("Finishing Guest::get_annotation_key sub");
    return $key;
}

=pod

=head2 network_interfaces

=head3 PURPOSE

Returns all network interface information in hash format

=head3 PARAMETERS

=over

=item vmname

Name of virtual machine

=back

=head3 RETURNS

Hash with all network interfaces and their information

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

=head3 TEST COVERAGE

=cut

sub network_interfaces {
    my ($vmname) = @_;
    &Log::debug("Starting Guest::network_interfaces sub");
    &Log::debug1("Opts are: vmname=>'$vmname'");
    my %interfaces = ();
    my $view       = &Guest::entity_property_view( $vmname, 'VirtualMachine',
        'config.hardware.device' );
    my $devices = $view->get_property('config.hardware.device');
    for my $device (@$devices) {
        &Log::dumpobj( "device", $device );
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
    &Log::dumpobj( "interface", \%interfaces );
    &Log::debug("Finishing Guest::network_interfaces sub");
    return \%interfaces;
}

=pod

=head2 generate_network_setup

=head3 PURPOSE

Generates a network DeviceConfigSpec for all interfaces for installation

=head3 PARAMETERS

=over

=item os_temp

The name of the template

=back

=head3 RETURNS

A DeviceConfigSpec for reconfiguring the network interfaces

=head3 DESCRIPTION

=head3 THROWS

Template::Status if no template is found
Entity::HWError if unknown interface type is found

=head3 COMMENTS

=head3 TEST COVERAGE

=cut

sub generate_network_setup {
    my ($os_temp) = @_;
    my @return;
    &Log::debug("Starting Guest::generate_network_sub");
    &Log::debug("Opts are: os_temp=>'$os_temp'");
    if ( !defined( &Support::get_hash( 'template', $os_temp ) ) ) {
        Template::Status->throw(
            error    => 'Template does not exists',
            template => $os_temp
        );
    }
    my $os_temp_path = &Support::get_key_value( 'template', $os_temp, 'path' );
    my $os_temp_view =
      &VCenter::moref2view( &VCenter::path2moref($os_temp_path) );
    my %interfaces = %{ &Guest::network_interfaces( $os_temp_view->name ) };
    my @mac        = @{ &Misc::generate_macs( scalar( keys %interfaces ) ) };
    for my $key ( keys %interfaces ) {
        my $ethernetcard;
        if ( $interfaces{$key}->{type} eq 'VirtualE1000' ) {
            &Log::debug("Generating setup for a E1000 device");
            $ethernetcard = VirtualE1000->new(
                addressType      => 'Manual',
                macAddress       => pop(@mac),
                wakeOnLanEnabled => 1,
                key              => $key
            );
        }
        elsif ( $interfaces{$key}->{type} eq 'VirtualVmxnet2' ) {
            &Log::debug("Generating setup for a VirtualVmxnet2");
            $ethernetcard = VirtualVmxnet2->new(
                addressType      => 'Manual',
                macAddress       => pop(@mac),
                wakeOnLanEnabled => 1,
                key              => $key
            );
        }
        elsif ( $interfaces{$key}->{type} eq 'VirtualVmxnet3' ) {
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
        &Log::dumpobj( "deviceconfigspec", $deviceconfigspec );
        push( @return, $deviceconfigspec );
    }
    &Log::debug("Returning array network devices Config Spec");
    return @return;
}

=pod

=head2 CustomizationAdapterMapping_generator

=head3 PURPOSE

Generates a CustomizationAdapterMapping for installation

=head3 PARAMETERS

=over

=item vmname

Name of Virtual Machine

=back

=head3 RETURNS

Array ref with CustomizationAdapterMapping created for all interfaces

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

=head3 TEST COVERAGE

=cut

sub CustomizationAdapterMapping_generator {
    my ($vmname) = @_;
    &Log::debug("Starting Guest::CustomizationAdapterMapping_generator sub");
    &Log::debug("Opts are: vmname=>'$vmname'");
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
        &Log::dumpobj( "nicsetting", $nicsetting );
        push( @return, $nicsetting );
    }
    &Log::dumpobj( "CustomizationAdapterMapping_array", \@return );
    &Log::debug("Finishing Guest::CustomizationAdapterMapping_generator sub");
    return \@return;
}

=pod

=head2 get_hw

=head3 PURPOSE

Returns all requested hardwares of a vm

=head3 PARAMETERS

=over

=item vmname

Name of Virtual Machine

=item hw

Type of hardware to search for

=back

=head3 RETURNS

Array ref with all hardwares as managed objects

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

=head3 TEST COVERAGE

=cut

sub get_hw {
    my ( $vmname, $hw ) = @_;
    &Log::debug("Starting Guest::get_hw sub");
    &Log::debug("Opts are: vmname=>'$vmname', hw=>'$hw'");
    my @hw   = ();
    my $view = &Guest::entity_property_view( $vmname, 'VirtualMachine',
        'config.hardware.device' );
    &Log::debug("Starting loop through hardver");
    my $devices = $view->get_property('config.hardware.device');
    foreach ( @{$devices} ) {
        &Log::dumpobj( "device", $_ );
        if ( $_->isa($hw) ) {
            &Log::debug("Found requrested hardver pushing to return");
            push( @hw, $_ );
        }
    }
    &Log::dumpobj( $hw, \@hw );
    &Log::debug("Finishing Guest:get_hw sub");
    return \@hw;
}

=pod

=head2 key2hw

=head3 PURPOSE

Returns hardware object according to requested key

=head3 PARAMETERS

=over

=item vmname

Name of Virtual Machine

=item key

Hardware key number

=back

=head3 RETURNS

A managed object containing the requested hardware

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

=head3 TEST COVERAGE

=cut

sub key2hw {
    my ( $vmname, $key ) = @_;
    &Log::debug("Starting Guest::key2hw sub");
    &Log::debug1("Opts are: vmname=>'$vmname', key=>'$key'");
    my $hw;
    my $view = &Guest::entity_property_view( $vmname, 'VirtualMachine',
        'config.hardware.device' );
    &Log::debug("Starting loop through hardver");
    my $devices = $view->get_property('config.hardware.device');
    foreach ( @{$devices} ) {
        &Log::dumpobj( "device", $_ );
        if ( $_->{key} eq $key ) {
            &Log::debug("Found requrested hardver pushing to return");
            $hw = $_;
        }
    }
    &Log::debug("Finishing Guest::key2hw sub");
    &Log::dumpobj( 'hw', $hw );
    return $hw;
}

=pod

=head2 poweron

=head3 PURPOSE

Powers on a Virtual Machine

=head3 PARAMETERS

=over

=item vmname

Name of Virtual Machine

=back

=head3 RETURNS

True on success
False if machine is already powered on

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

=head3 TEST COVERAGE

=cut

sub poweron {
    my ($vmname) = @_;
    &Log::debug("Starting Guest::poweron sub");
    &Log::debug1("Opts are: vmname=>'$vmname'");
    my $view =
      &Guest::entity_property_view( $vmname, 'VirtualMachine',
        'runtime.powerState' );
    my $powerstate = $view->get_property('runtime.powerState');
    if ( $powerstate->val ne "poweredOff" ) {
        &Log::info("Machine is already powered on");
        return 0;
    }
    my $task = $view->PowerOnVM_Task;
    &VCenter::Task_Status($task);
    &Log::debug("Finishing Guest::poweron sub");
    return 1;
}

=pod

=head2 poweroff

=head3 PURPOSE

Poweres off a Virtual Machine

=head3 PARAMETERS

=over

=item vmname

Name of Virtual Machine

=back

=head3 RETURNS

True on success
False if machine is already powered on

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

=head3 TEST COVERAGE

=cut

sub poweroff {
    my ($vmname) = @_;
    &Log::debug("Starting Guest::poweroff sub");
    &Log::debug("Opts are: vmname=>'$vmname'");
    my $view =
      &Guest::entity_property_view( $vmname, 'VirtualMachine',
        'runtime.powerState' );
    my $powerstate = $view->get_property('runtime.powerState');
    if ( $powerstate->val eq "poweredOff" ) {
        &Log::info("Machine is already powered off");
        return 0;
    }
    my $task = $view->PowerOffVM_Task;
    &VCenter::Task_Status($task);
    &Log::debug("Finishing Guest::poweroff sub");
    return 1;
}

=pod

=head2 revert_to_snapshot

=head3 PURPOSE

Reverts a Virtual Machine to requested snapshot

=head3 PARAMETERS

=over

=item vmname

Name of Virtual Machine

=item id

Id of snapshot to revert to

=back

=head3 RETURNS

True on success
False on failure

=head3 DESCRIPTION

=head3 THROWS

Entity::Snapshot if no snapshots are found

=head3 COMMENTS

=head3 TEST COVERAGE

=cut

sub revert_to_snapshot {
    my ( $vmname, $id ) = @_;
    &Log::debug("Starting Guest::revert_to_snapshot sub");
    &Log::debug1("Opts are: vmname=>'$vmname', id=>'$id'");
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
            my $moref = &VCenter::moref2view( $snapshot->snapshot );
            my $task = $moref->RevertToSnapshot_Task( suppressPowerOn => 1 );
            &VCenter::Task_Status($task);
            &Log::debug("Finishing GuestManagement::revert_to_snapshot sub");
            return 1;
        }
    }
    &Log::debug("Could not revert to requested id");
    return 0;
}

=pod

=head2 find_snapshot_by_id

=head3 PURPOSE

Returns snapshot according to requested id

=head3 PARAMETERS

=over

=item snapshot_view

Snapshot managed object of virtual machine

=item id

Id of requested snpashot

=back

=head3 RETURNS

Managed object of requested snapshot

=head3 DESCRIPTION

find_snapshot_by_id is used for recursing through a tree structure of snapshot to search for requested snapshot object

=head3 THROWS

=head3 COMMENTS

=head3 TEST COVERAGE

=cut

sub find_snapshot_by_id {
    my ( $snapshot_view, $id ) = @_;
    &Log::debug("Starting Guest::find_snapshot_by_id sub");
    &Log::debug1("Opts are: id=>'$id'");
    &Log::dumpobj( "snapshot_view", $snapshot_view );
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
    &Log::debug("Finishing Guest::find_snapshot_by_id sub");
    &Log::dumpobj( "returning snapshot", $return );
    return $return;
}

=pod

=head2 create_snapshot

=head3 PURPOSE

Creates a snapshot for Virtual Machine

=head3 PARAMETERS

=over

=item vmname

Name of Virtual Machine

=item snap_name

Name of requested snapshot

=item desc

Description of requested snapshot

=back

=head3 RETURNS

True on success

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

=head3 TEST COVERAGE

=cut

sub create_snapshot {
    my ( $vmname, $snap_name, $desc ) = @_;
    &Log::debug("Starting Guest::create_snapshot sub");
    &Log::debug(
        "Opts are: vmname=>'$vmname', snap_name=>'$snap_name', desc=>'$desc'");
    my $view = &Guest::entity_name_view( $vmname, 'VirtualMachine' );
    my $task = $view->CreateSnapshot_Task(
        name        => $snap_name,
        description => $desc,
        memory      => 1,
        quiesce     => 1
    );
    &VCenter::Task_Status($task);
    &Log::debug("Finishing Guest::create_snapshot sub");
    return 1;
}

=pod

=head2 remove_all_snapshot

=head3 PURPOSE

Removes all snapshots from a Virtual Machine

=head3 PARAMETERS

=over

=item vmname

Name of Virtual Machine

=back

=head3 RETURNS

True on success

=head3 DESCRIPTION

=head3 THROWS

Entity::Snapshot if no snpashots found

=head3 COMMENTS

=head3 TEST COVERAGE

=cut

sub remove_all_snapshots {
    my ($vmname) = @_;
    &Log::debug("Starting Guest::remove_all_snapshot sub");
    &Log::debug("Opts are: vmname=>'$vmname'");
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
    &VCenter::Task_Status($task);
    &Log::debug("Finishing Guest::remove_all_snapshot sub");
    return 1;
}

=pod

=head2 remove_snapshot

=head3 PURPOSE

Removes requested snapshot

=head3 PARAMETERS

=over

=item vmname

Name of Virtual Machine

=item id

Id of snapshot

=back

=head3 RETURNS

True on success
False on failure

=head3 DESCRIPTION

=head3 THROWS

Entity::Snapshot if no snapshots found

=head3 COMMENTS

=head3 TEST COVERAGE

=cut

sub remove_snapshot {
    my ( $vmname, $id ) = @_;
    &Log::debug("Starting Guest::remove_snapshot sub");
    &Log::debug1("Opts are: vmname=>'$vmname', id=>'$id'");
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
                &VCenter::Task_Status($task);
                &Log::debug("Finishing Guest::remove_snapshot sub");
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

=pod

=head2 remove_hw

=head3 PURPOSE

Removes a requested managed object

=head3 PARAMETERS

=over

=item vmname

Name of Virtual Machine

=item hw

Managed object of requested hardware

=back

=head3 RETURNS

True on success

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

=head3 TEST COVERAGE

=cut

sub remove_hw {
    my ( $vmname, $hw ) = @_;
    &Log::debug("Starting Guest::remove_hw sub");
    &Log::debug1("Opts are: vmname=>'$vmname'");
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
    &Log::debug("Finishing Guest::remove_hw sub");
    return 1;
}

=pod

=head2 promote

=head3 PURPOSE

Coverts a linked clone Virtual Machine to an independent full clone

=head3 PARAMETERS

=over

=item vmname

Name of Virtual Machine

=back

=head3 RETURNS

True on success

=head3 DESCRIPTION

After machine is converted it is removed from linked clone folder to the folder of the ticket

=head3 THROWS

=head3 COMMENTS

=head3 TEST COVERAGE

=cut

sub promote {
    my ($vmname) = @_;
    &Log::debug("Starting Guest::promote sub");
    &Log::debug("Opts are: vmname=>'$vmname'");
    &Guest::poweroff($vmname);
    my $view = &Guest::entity_name_view( $vmname, 'VirtualMachine' );
    my $task = $view->PromoteDisks_Task( unlink => 1 );
    &VCenter::Task_Status($task);
    my $splitted = &Misc::vmname_splitter($vmname);

    if ( !&VCenter::exists_entity( $splitted->{ticket}, 'Folder' ) ) {
        &VCenter::create_folder( $splitted->{ticket}, 'vm' );
    }
    &VCenter::move_into_folder( $vmname, $splitted->{ticket} );
    &Log::debug("Finishing Guest::promote sub");
    return 1;
}

=pod

=head2 list_snapshot

=head3 PURPOSE

List snapshots and prints to stdout

=head3 PARAMETERS

=over

=back

=head3 RETURNS

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

Maybe need to rethink to put printing into outer call, this should just return some information for easier printing

=head3 TEST COVERAGE

=cut

sub list_snapshot {
    my ( $snapshotinfo, $view) = @_;
    &Log::debug("Starting Guest::list_snapshot sub");
    &Log::dumpobj( "snapshotinfo", $snapshotinfo);
    &Log::dumpobj( "snapshot", $view );
    $snapshotinfo->{$view->{id}} = { name => $view->{name}, createTime => $view->{createTime}, description => $view->{description}};
    ($view->{snapshot}->{value} eq $snapshotinfo->{CUR}) and $snapshotinfo->{$view->{id}}->{current} = 1;
    if ( defined( $view->{childSnapshotList}) ) {
        foreach( @{$view->{childSnapshotList}}) {
            $snapshotinfo = &Guest::list_snapshot( $snapshotinfo, $_ );
        }
    } else {
        &Log::debug("No Child Snapshots defined");
    }
    &Log::dumpobj("snapshotinfo", $snapshotinfo);
    &Log::debug("Finishing Guest::list_snapshot sub");
    return $snapshotinfo;
}

=pod

=head2 run_command

=head3 PURPOSE

Runs a requested program in the guest that has vmware tools installed

=head3 PARAMETERS

=over

=item info

A hash ref with needed information
Needs to contain following items:

=item vmname

Name of Virtual Machine

=item guestusername

Username for authentication

=item guestpassword

Password for authentication

=item workdir

The directory we should use for running the command

=item prog

Name of the program we should run

=item prog_arg

The arguments we should give the program

=item env

The Environmental arguments we should give the program

=back

=head3 RETURNS

The pid of the program started

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

=head3 TEST COVERAGE

=cut

sub run_command {
    my ($info) = @_;
    &Log::debug("Starting Guest::run_command sub");
    &Log::loghash( "Info options, ", $info );
    my $view = &Guest::entity_name_view( $info->{vmname}, 'VirtualMachine' );
    my $guestCreds = &Guest::guest_cred(
        $info->{vmname},
        $info->{guestusername},
        $info->{guestpassword}
    );
    my $guestOP       = &VCenter::get_manager("guestOperationsManager");
    my $guestProcMan  = &VCenter::moref2view( $guestOP->{processManager} );
    my $guestProgSpec = GuestProgramSpec->new(
        workingDirectory => $info->{workdir},
        programPath      => $info->{prog},
        arguments        => $info->{prog_arg},
        envVariables     => [ $info->{env} ]
    );
    &Log::dumpobj( "guestProgSpec", $guestProgSpec );
    my $pid = $guestProcMan->StartProgramInGuest(
        vm   => $view,
        auth => $guestCreds,
        spec => $guestProgSpec
    );
    &Log::debug("Returning=>'$pid'");
    &Log::debug("Finishing Guest::run_command sub");
    return $pid;
}

=pod

=head2 transfer_to_guest

=head3 PURPOSE

Transfer file to guest

=head3 PARAMETERS

=over

=item info

A hash with all information required for sub
Information required:

=item vmname

Name of Virtual Machine

=item guestusername

Username to authenticate with

=item guestpassword

Password to authenticate with

=item source

Path to file to upload

=item dest

Destination of upload

=item overwrite

Should uploaded file overwrite any present files

=back

=head3 RETURNS

True on success

=head3 DESCRIPTION

=head3 THROWS

Entity::TransferError if transfer was not successful

=head3 COMMENTS

=head3 TEST COVERAGE

=cut

sub transfer_to_guest {
    my ($info) = @_;
    &Log::debug("Starting Guest::transfer_to_guest sub");
    &Log::loghash( "Info options, ", $info );
    my $view = &Guest::entity_name_view( $info->{vmname}, 'VirtualMachine' );
    my $guestCreds = &Guest::guest_cred(
        $info->{vmname},
        $info->{guestusername},
        $info->{guestpassword}
    );
    my $guestOP     = &VCenter::get_manager("guestOperationsManager");
    my $filemanager = &VCenter::moref2view( $guestOP->{fileManager} );
    &Log::dumpobj( "filemanager", $filemanager );
    my $fileattr = GuestFileAttributes->new();
    my $size     = -s $info->{source};
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
    print "Information about file:'" . $info->{source} . "'\n";
    print "Size of file: $size bytes\n";
    my $ua = LWP::UserAgent->new();
    $ua->ssl_opts( verify_hostname => 0 );
# FIXME refactor or exception
    open( my $fh, "<", $info->{source} ) or die "Could not open file";
    my $content = do { local $/; <$fh> };

    my $req = $ua->put( $transferinfo, Content => $content );

    if ( $req->is_success() ) {
        &Log::debug( "OK: ", $req->content );
    }
    else {
        Entity::TransferError->throw( error => $req->as_string, entity => $info->{vmname}, filename => $info->{source} );
    }
    &Log::debug("Finishing Guest:transfer_to_guest sub");
    return 1;
}

=pod

=head2 transfer_from_guest

=head3 PURPOSE

Transfers files from guest

=head3 PARAMETERS

=over

=item info

A hash containing information required
Required information:

=item vmname

Name of virtual machine

=item guestusername

Username to authenticate with

=item guestpassword

Password to authenticate with

=item source

Path to remote file to download

=item dest

Destination to put file

=back

=head3 RETURNS

True on success

=head3 DESCRIPTION

=head3 THROWS

Entity::TransferError if there was a transfer error

=head3 COMMENTS

=head3 TEST COVERAGE

=cut

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
    my $guestOP     = &VCenter::get_manager("guestOperationsManager");
    my $filemanager = &VCenter::moref2view( $guestOP->{fileManager} );
    my $transferinfo;
    eval {
        $transferinfo = $filemanager->InitiateFileTransferFromGuest(
            vm            => $view,
            auth          => $guestCreds,
            guestFilePath => $info->{source}
        );
    };

    if ($@) {
        &Log::dumpobj( "transferinfo_erro", $@ );
        Entity::TransferError->throw(
            error    => 'Could not retrieve Transfer information',
            entity   => $info->{vmname},
            filename => $info->{source}
        );
    }
    print "Information about file: $info->{source} \n";
    print "Size: " . $transferinfo->size . " bytes\n";
    print "modification Time: "
      . $transferinfo->attributes->modificationTime
      . " and access Time : "
      . $transferinfo->attributes->accessTime . "\n";
    LWP::Simple->import;
    if ( !defined( $info->{dest} ) ) {
        my $basename = basename( $info->{source} );
        my $content  = get( $transferinfo->url );
        open( my $fh, ">", "/tmp/$basename" );
        print $fh "$content";
        close($fh);
    }
    else {
        &Log::debug( "Downloading file to: '" . $info->{dest} . "'" );
        my $status = getstore( $transferinfo->url, $info->{dest} );
    }
    &Log::debug("Finishing Guest::transfer_from_guest sub");
    return 1;
}

=pod

=head1 process_info

=head2 PURPOSE

Returns info about process in Virtual Machine

=head2 PARAMETERS

=over

=item info

A hash containing information required
Required information:

=item vmname

Name of virtual machine

=item guestusername

Username to authenticate with

=item guestpassword

Password to authenticate with

=item pid

Pid of the requested program. Pid 0 returns all programs

=back

=head2 RETURNS

Array ref with program objects

=head2 DESCRIPTION

=head2 THROWS

Entity::NumException if no pid is found

=head2 COMMENTS

=head2 TEST COVERAGE

=cut

sub process_info {
    my ($info) = @_;
    &Log::debug("Starting Guest::process_info sub");
    my $guestCreds = &Guest::guest_cred(
        $info->{vmname},
        $info->{guestusername},
        $info->{guestpassword}
    );
    my $guestOP        = &VCenter::get_manager("guestOperationsManager");
    my $processmanager = &VCenter::moref2view( $guestOP->{processManager} );
    my $view = &Guest::entity_name_view( $info->{vmname}, 'VirtualMachine' );
    my $data;
    if ( $info->{pid} != 0 ) {
        $data = $processmanager->ListProcessesInGuest(
            vm   => $view,
            auth => $guestCreds,
            pids => [ $info->{pid} ]
        );
    }
    else {
        $data = $processmanager->ListProcessesInGuest(
            vm   => $view,
            auth => $guestCreds
        );
    }
    if ( !@{$data} ) {
        Entity::NumException->throw(
            error  => "No processes found with requested PID",
            entity => $info->{vmname},
            num    => $info->{pid}
        );
    }
    &Log::dumpobj( "data", $data );
    &Log::debug("Finishing Guest::process_info sub");
    return $data;
}

=pod

=head2 guest_cred

=head3 PURPOSE

Retrieves a NamePasswordAthentication and validates credentials if they are working

=head3 PARAMETERS

=over

=item vmname

Name of Virtual Machine

=item guestusername

Username to authenticate with

=item guestpassword

Password to authenticate with

=back

=head3 RETURNS

NamePasswordAthentication object

=head3 DESCRIPTION

=head3 THROWS

Entity::Auth if authentication fails

=head3 COMMENTS

=head3 TEST COVERAGE

=cut

sub guest_cred {
    my ( $vmname, $guestusername, $guestpassword ) = @_;
    &Log::debug("Starting Guest::guest_cred sub");
    &Log::debug(
"Opts are: vmname=>'$vmname', guestusername=>'$guestusername', guestpassword=>'$guestpassword'"
    );
    my $guestOP   = &VCenter::get_manager("guestOperationsManager");
    my $authMgr   = &VCenter::moref2view( $guestOP->{authManager} );
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
    &Log::debug("Finishing Guest::guest_cred sub");
    &Log::dumpobj( "guestauth", $guestAuth );
    return $guestAuth;
}

1
