package Guest;

use strict;
use warnings;

BEGIN {
    use Exporter;
    our @ISA    = qw( Exporter );
    our @EXPORT = qw( );
}

sub entity_name_view {
    my ( $name, $type ) = @_;
    &Log::debug("Retrieving entity name view, name=>'$name', type=>'$type'");
    &VCenter::num_check( $name, $type );
    my $view = Vim::find_entity_view(
        view_type  => $type,
        properties => ['name'],
        filter     => { name => $name }
    );
    return $view;
}

sub entity_full_view {
    my ( $name, $type ) = @_;
    &Log::debug(
        "Retrieving entity full view sub, name=>'$name', type=>'$type'");
    &VCenter::num_check( $name, $type );
    my $view =
      Vim::find_entity_view( view_type => $type, filter => { name => $name } );
    return $view;
}

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
    return $view;
}

sub vm_memory {
    my ($name) = @_;
    &Log::debug("Retrieving VirtualMachine memory size in MB, name=>'$name'");
    my $view = Vim::find_entity_view(
        view_type  => 'VirtualMachine',
        properties => ['summary.config.memorySizeMB'],
        filter     => { name => $name }
    );
    return $view->get_property('summary.config.memorySizeMB');
}

sub vm_numcpu {
    my ($name) = @_;
    &Log::debug("Retrieving VirtualMachine Cpu count, name=>'$name'");
    my $view = Vim::find_entity_view(
        view_type  => 'VirtualMachine',
        properties => ['summary.config.numCpu'],
        filter     => { name => $name }
    );
    return $view->get_property('summary.config.numCpu');
}

sub find_last_snapshot {
    my ($snapshot_view) = @_;
    &Log::debug( "Starting Guest::find_last_snapshot sub, name=>'"
          . $snapshot_view->name
          . "',id=>'"
          . $snapshot_view->id
          . "'" );
    if ( defined( $snapshot_view->[0]->{'childSnapshotList'} ) ) {
        &find_last_snapshot( $snapshot_view->[0]->{'childSnapshotList'} );
    }
    else {
        &Log::debug(
            "Found snapshot returning, name=>'" . $snapshot_view->name . "'" );
        return $snapshot_view;
    }
}

sub get_altername {
    my ($vmname) = @_;
    &Log::debug("Starting Guest::get_altername sub, vmname=>'$vmname'");
    &VCenter::num_check( $vmname, 'VirtualMachine' );
    my $view = Vim::find_entity_view(
        view_type  => 'VirtualMachine',
        properties => ['value'],
        filter     => { name => $vmname }
    );
    my $key = &get_annotation_key( $vmname, "alternateName" );
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

sub get_annotation_key {
    my ( $vmname, $name ) = @_;
    &Log::debug(
"Starting Guest::get_annotation_key sub, vmname=>'$vmname', key=>'$name'"
    );
    &VCenter::num_check( $vmname, 'VirtualMachine' );
    my $view = Vim::find_entity_view(
        view_type  => 'VirtualMachine',
        properties => ['availableField'],
        filter     => { name => $vmname }
    );
    foreach ( @{ $view->availableField } ) {
        if ( $_->name eq $name ) {
            &Log::debug( "Found key returning value=>'" . $_->key . "'" );
            return $_->key;
        }
    }
    &Log::debug("No annotation key was found with requested name");
    return 0;
}

sub network_interfaces {
    my ($vmname) = @_;
    &Log::debug("Starting Guest::network_interfaces sub, vmname=>'$vmname'");
    my %interfaces = ();
    my $view       = Vim::find_entity_view(
        view_type  => 'VirtualMachine',
        properties => ['config.hardware.device'],
        filter     => { name => $vmname }
    );
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
        &Log::debug(
"Interface gathered information, mac=>'$interfaces{$key}->{mac}', controllerkey=>'$interfaces{$key}->{controllerkey}', unitnumber=>'$interfaces{$key}->{unitnumber}', label=>'$interfaces{$key}->{label}', summary=>'$interfaces{$key}->{summary}', type=>'$interfaces{$key}->{type}', key=>'$key'"
        );
    }
    &Log::debug("Returning interfaces hash");
    return \%interfaces;
}

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
    my %keys = %{ &network_interfaces( $os_temp_view->name ) };
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

sub CustomizationAdapterMapping_generator {
    my ($vmname) = @_;
    &Log::debug(
"Starting Guest::CustomizationAdapterMapping_generator sub, vmname=>'$vmname'"
    );
    my @return;
    for my $key ( keys &network_interfaces($vmname) ) {
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
sub poweron {
    my ($vmname) = @_;
    &Log::debug("Starting Guest::poweron sub, vmname=>'$vmname'");
    &VCenter::num_check( $vmname, 'VirtualMachine' );
    my $view = Vim::find_entity_view(
        view_type  => 'VirtualMachine',
        properties => ['runtime.powerState'],
        filter     => { name => $vmname }
    );
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
    my $view = Vim::find_entity_view(
        view_type  => 'VirtualMachine',
        properties => ['runtime.powerState'],
        filter     => { name => $vmname }
    );
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

#TODO
sub revert_to_snapshot {
    my ( $vmname, $id ) = @_;
    &Log::debug(
"Starting GuestManagement::revert_to_snapshot sub, vmname=>'$vmname', id=>'$id'\n"
    );
    my $view = Vim::find_entity_view(
        view_type  => 'VirtualMachine',
        properties => ['snapshot'],
        filter     => { name => $vmname }
    );
    if ( !defined($view) ) {
        SDK::Error::Entity::NumException->throw(
            error  => 'Could not find VM entity',
            entity => $vmname,
            count  => '0'
        );
    }
    if ( defined( $view->snapshot ) ) {
        foreach ( @{ $view->snapshot->rootSnapshotList } ) {
            my $snapshot = &find_snapshot_by_id( $_, $id );
            if ( defined($snapshot) ) {
                Util::trace( 1, "Found Id reverting\n" );
                my $moref = Vim::get_view( mo_ref => $snapshot->snapshot );
                my $task =
                  $moref->RevertToSnapshot_Task( suppressPowerOn => 1 );
                &Vcenter::Task_getStatus($task);
                Util::trace( 4,
"Finishing GuestManagement::revert_to_snapshot sub, return=>'success'\n"
                );
                return 1;
            }
        }
    }
    else {
        SDK::Error::Entity::Snapshot->throw(
            error => "No snapshot found by vm $vmname" );
    }
}

sub create_snapshot {
    my ( $vmname, $snap_name, $desc ) = @_;
    &Log::debug(
"Starting Guest::create_snapshot sub, vmname=>'$vmname', snap_name=>'$snap_name', desc=>'$desc'"
    );
    &VCenter::num_check( $vmname, 'VirtualMachine' );
    my $view = &entity_name_view( $vmname, 'VirtualMachine' );
    my $task = $view->CreateSnapshot_Task(
        name        => $snap_name,
        description => $desc,
        memory      => 1,
        quiesce     => 1
    );
    &Vcenter::Task_Status($task);
    return 1;
}

sub list_snapshot {
    my ($vmname) = @_;
    &Log::debug("Starting Guest::list_snapshot sub, vmname=>'$vmname'");
    &VCenter::num_check( $vmname, 'VirtualMachine' );
    my $view = &entity_property_view( $vmname, 'VirtualMachine', 'snapshot' );
    if ( !defined( $view->snapshot ) ) {
        Entity::Snapshot->throw(
            error    => "Entity has no snapshots defined",
            entity   => $vmname,
            snapshot => 0
        );
    }
    my $current_snapshot = $view->snapshot->currentSnapshot->value;
    foreach ( @{ $view->snapshot->rootSnapshotList } ) {
        &traverse_snapshot( $_, $current_snapshot );
    }
    return 1;
}

sub traverse_snapshot {
    my ( $snapshot_moref, $current_snapshot ) = @_;
    &Log::debug(
"Starting Guest::traverse_snapshot sub, current_snapshot=>'$current_snapshot', snapshot_moref_name=>'"
          . $snapshot_moref->name
          . "'" );
    my $current = "";
    if ( $snapshot_moref->snapshot->value eq $current_snapshot ) {
        &Log::debug("Found current active snapshot");
        $current = "*CUR* ";
    }
    &Log::normal( $current
          . "ID => '"
          . $snapshot_moref->id
          . "', name => '"
          . $snapshot_moref->name
          . "', createTime => '"
          . $snapshot_moref->createTime
          . "', description => '"
          . $snapshot_moref->description
          . "'" );
    if ( defined( $snapshot_moref->{'childSnapshotList'} ) ) {
        foreach ( @{ $snapshot_moref->{'childSnapshotList'} } ) {
            &traverse_snapshot( $_, $current_snapshot );
        }
    }
    return 0;
}

### print functions

sub short_vm_info {
    my ($name) = @_;
    &Log::debug("Starting Guest::short_vm_info sub, name=>'$name'");
    &VCenter::num_check( $name, 'VirtualMachine' );
    my $view = Vim::find_entity_view(
        view_type  => 'VirtualMachine',
        properties => [ 'name', 'guest', 'summary.runtime.powerState' ],
        filter => { name => $name }
    );
    &Log::normal( "VMname:'" . $view->name );
    my $powerState = $view->get_property('summary.runtime.powerState');
    &Log::normal( "\tPower State:'" . $powerState->val . "'" );

    &Log::normal(
        "\tAlternate name: '" . &Guest::get_altername( $view->name ) . "'" );
    if ( $view->guest->toolsStatus eq 'toolsNotInstalled' ) {
        &Log::normal("\tTools not installed. Cannot extract some information");
    }
    else {
        if ( defined( $view->guest->net ) ) {
            foreach ( @{ $view->guest->net } ) {
                if ( defined( $_->ipAddress ) ) {
                    &Log::normal( "\tNetwork => '"
                          . $_->network
                          . "', with ipAddresses => [ "
                          . join( ", ", @{ $_->ipAddress } )
                          . " ]" );
                }
                else {
                    &Log::normal( "\tNetwork => '" . $_->network . "'" );
                }
            }
            if ( defined( $view->guest->hostName ) ) {
                &Log::normal( "\tHostname: '" . $view->guest->hostName . "'" );
            }
        }
        else {
            &Log::normal("\tNo network information available");
        }
    }
    my $vm_info = &Misc::vmname_splitter( $view->name );
    my $os;
    if ( $vm_info->{type} =~ /xcb/ ) {
        &Log::debug("Product is an XCB product");
        $os = "$vm_info->{family}_$vm_info->{version}";
    }
    elsif ( $vm_info->{type} ne 'unknown' ) {
        &Log::debug("Product is known");
        $os =
"$vm_info->{family}_$vm_info->{version}_$vm_info->{lang}_$vm_info->{arch}_$vm_info->{type}";
    }
    if ( $vm_info->{uniq} ne 'unknown' ) {
        if ( defined( &Support::get_key_info( 'template', $os ) ) ) {
            &Log::normal( "\tDefault login : '"
                  . &Support::get_key_value( 'template', $os, 'username' )
                  . "' / '"
                  . &Support::get_key_value( 'template', $os, 'password' )
                  . "'" );
        }
        else {
            &Log::normal(
                "\tRegex matched an OS, but no template found to it os => '$os'"
            );
        }
    }
    else {
        &Log::normal("\tVmname not standard name => '$name'");
    }
}

1
__END__
