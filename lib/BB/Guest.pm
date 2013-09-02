package Guest;

use strict;
use warnings;

BEGIN {
    use Exporter;
    our @ISA = qw( Exporter );
    our @EXPORT = qw( );
}

sub entity_name_view($$) {
    my ( $name, $type ) = @_;
    &Log::debug("Retrieving entity name view, name=>'$name', type=>'$type'");
    my $view = Vim::find_entity_view( view_type => $type, properties => [ 'name' ], filter => { name => $name } );
    return $view;
}

sub vm_memory($$) {
    my ( $name ) = @_;
    &Log::debug("Retrieving VirtualMachine memory size in MB, name=>'$name'");
    my $view = Vim::find_entity_view( view_type => 'VirtualMachine', properties => [ 'summary.config.memorySizeMB' ], filter => { name => $name } );
    return $view->get_property( 'summary.config.memorySizeMB' );
}

sub vm_numcpu($) {
    my ( $name ) = @_;
    &Log::debug("Retrieving VirtualMachine Cpu count, name=>'$name'");
    my $view = Vim::find_entity_view( view_type => 'VirtualMachine', properties => [ 'summary.config.numCpu' ], filter => { name => $name } );
    return $view->get_property( 'summary.config.numCpu' );
}

sub find_last_snapshot($) {
    my ( $snapshot_view ) = @_;
    &Log::debug("Starting Guest::find_last_snapshot sub, name=>'" . $snapshot_view->name . "',id=>'" . $snapshot_view->id . "'");
    if ( defined( $snapshot_view->[0]->{'childSnapshotList'} ) ) {
        &find_last_snapshot( $snapshot_view->[0]->{'childSnapshotList'} );
    } else {
        &Log::debug("Found snapshot returning, name=>'" . $snapshot_view->name . "'");
        return $snapshot_view;
    }
}

sub network_interfaces($) {
    my ( $vmname ) = @_;
    &Log::debug("Starting Guest::network_interfaces sub, vmname=>'$vmname'");
    my %interfaces = ();
    my $view = Vim::find_entity_view( view_type => 'VirtualMachine', properties => [ 'config.hardware.device' ], filter => { name => $vmname } );
    my $devices = $view->get_property('config.hardware.device');
    for my $device ( @$devices ) {
        if ( !$device->isa( 'VirtualEthernetCard' ) ) {
            &Log::debug("Device is not a network interface, skipping");
            next;
        }
        my $key = $device->key;
        $interfaces{$key} = {};
        if ( $device->isa( 'VirtualE1000' ) ) {
            &Log::debug("Interface $key is a VirtualE1000");
            $interfaces{$key}->{type} = 'VirtualE1000';
        } elsif ( $device->isa( 'VirtualVmxnet2' ) ) {
            &Log::debug("Interface $key is a VirtualVmxnet2");
            $interfaces{$key}->{type} = 'VirtualVmxnet2';
        } elsif ( $device->isa( 'VirtualVmxnet3' ) ) {
            &Log::debug("Interface $key is a VirtualVmxnet3");
            $interfaces{$key}->{type} = 'VirtualVmxnet3';
        } else {
            Entity::HWError->throw( error => 'Interface object is unhandeled', entity => $vmname, hw => $key );
        }
        $interfaces{$key}->{mac} = $device->macAddress;
        $interfaces{$key}->{controllerkey} = $device->controllerKey;
        $interfaces{$key}->{unitnumber} = $device->unitNumber;
        $interfaces{$key}->{label} = $device->deviceInfo->label;
        $interfaces{$key}->{summary} = $device->deviceInfo->summary;
        &Log::debug("Interface gathered information, mac=>'$interfaces{$key}->{mac}', controllerkey=>'$interfaces{$key}->{controllerkey}', unitnumber=>'$interfaces{$key}->{unitnumber}', label=>'$interfaces{$key}->{label}', summary=>'$interfaces{$key}->{summary}', type=>'$interfaces{$key}->{type}', key=>'$key'");
    }
    &Log::debug("Returning interfaces hash");
    return \%interfaces;
}

sub generate_network_setup {
    my ( $os_temp ) = @_;
    my @return;
    &Log::debug("Starting Guest::generate_network_sub, os_temp=>'$os_temp'");
    if ( !defined( &Support::get_key_info( 'template', $os_temp ) ) ) {
        Template::Status->throw( error => 'Template does not exists', template => $os_temp );
    }
    my $os_temp_path = &Support::get_key_value( 'template', $os_temp, 'path' );
    my $os_temp_view = &VCenter::moref2view( &VCenter::path2moref( $os_temp_path ) );
    my %keys = %{ &network_interfaces( $os_temp_view->name ) };
    my @mac = &Misc::generate_macs( scalar( keys %keys ) );
    for my $key ( keys %keys ) {
        my $ethernetcard;
        if ( $keys{$key}->{type} eq 'VirtualE1000' ) {
            &Log::debug("Generating setup for a E1000 device");
            $ethernetcard =VirtualE1000->new( addressType => 'Manual', macAddress => pop(@mac), wakeOnLanEnabled => 1, key => $key );
        } elsif ( $keys{$key}->{type} eq 'VirtualVmxnet2' ) {
            &Log::debug("Generating setup for a VirtualVmxnet2");
            $ethernetcard =VirtualVmxnet2->new( addressType => 'Manual', macAddress => pop(@mac), wakeOnLanEnabled => 1, key => $key );
        } elsif ($keys{$key}->{type} eq 'VirtualVmxnet3') {
            &Log::debug("Generating setup for a VirtualVmxnet3");
            $ethernetcard =VirtualVmxnet3->new( addressType => 'Manual', macAddress => pop(@mac), wakeOnLanEnabled => 1, key => $key );
        } else {
            Entity::HWError->throw( error => 'Interface Hash contains unknown type', entity => $os_temp, hw => $key );
        }
        my $operation = VirtualDeviceConfigSpecOperation->new( 'edit' );
        my $deviceconfigspec = VirtualDeviceConfigSpec->new( device => $ethernetcard, operation => $operation );
        push( @return, $deviceconfigspec );
    }
    &Log::debug("Returning array network devices Config Spec");
    return @return;
}

sub CustomizationAdapterMapping_generator {
    my ( $vmname ) = @_;
    &Log::debug("Starting Guest::CustomizationAdapterMapping_generator sub, vmname=>'$vmname'");
    my @return;
    for my $key ( keys &network_interfaces( $vmname ) ) {
        &Log::debug("Generating $key Adapter mapping");
        my $ip = CustomizationDhcpIpGenerator->new( );
        my $adapter = CustomizationIPSettings->new( dnsDomain => 'support.balabit', dnsServerList => [ '10.10.0.1' ], gateway => [ '10.21.255.254' ], subnetMask => '255.255.0.0', ip => $ip, netBIOS => CustomizationNetBIOSMode->new( 'enableNetBIOS' ) );
        my $nicsetting = CustomizationAdapterMapping->new( adapter => $adapter );
        push( @return, $nicsetting );
    }
    &Log::debug("Returning array of adapter mappings");
    return @return;
}

1
__END__
