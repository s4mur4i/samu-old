package Test;

use strict;
use warnings;

=pod

=head1 Test.pm

Subroutines for SAMU_Test/Test.pm

=cut

BEGIN {
    use Exporter;
    our @ISA    = qw( Exporter );
    our @EXPORT = qw( );
}

sub clonevm {
    my ( $template, $vmname, $folder, $clone_spec ) = @_;
    my $template_view = &Guest::entity_name_view( $template, 'VirtualMachine' );
    my $folder_view = &Guest::entity_name_view( $folder, 'Folder' );
    my $task = $template_view->CloneVM_Task(
        folder => $folder_view,
        name   => $vmname,
        spec   => $clone_spec
    );
    &VCenter::Task_Status($task);
    return 1;
}

sub create_test_vm {
    my ($name) = @_;
    &Log::debug("Starting Test::create_test_vm");
    &VCenter::num_check( 'test_1337', 'ResourcePool' );
    my $resource_pool = &Guest::entity_name_view( 'test_1337', 'ResourcePool' );
    &VCenter::num_check( 'test_1337', 'Folder' );
    my $folder = &Guest::entity_name_view( 'test_1337', 'Folder' );
    &VCenter::num_check( 'test_1337', 'DistributedVirtualSwitch' );
    my $host_view =
      &Guest::entity_name_view( 'vmware-it1.balabit', 'HostSystem' );
    my $network_list = Vim::get_views( mo_ref_array => $host_view->network );
    my @vm_devices;
    my $files = VirtualMachineFileInfo->new(
        logDirectory      => undef,
        snapshotDirectory => undef,
        suspendDirectory  => undef,
        vmPathName        => '[support] test_1337'
    );

    foreach (@$network_list) {
        if ( $_->name =~ /^test_1337_dvg/ ) {
            my $network          = $_;
            my $nic_backing_info = VirtualEthernetCardNetworkBackingInfo->new(
                deviceName    => 'test_1337_dvg',
                useAutoDetect => 1,
                network       => $network
            );
            my $vd_connect_info = VirtualDeviceConnectInfo->new(
                allowGuestControl => 1,
                connected         => 0,
                startConnected    => 1
            );
            my $nic = VirtualPCNet32->new(
                backing     => $nic_backing_info,
                key         => 0,
                addressType => 'generated',
                connectable => $vd_connect_info
            );
            my $nic_vm_dev_conf_spec = VirtualDeviceConfigSpec->new(
                device    => $nic,
                operation => VirtualDeviceConfigSpecOperation->new('add')
            );
            push( @vm_devices, $nic_vm_dev_conf_spec );
        }
    }
    my $config_spec = VirtualMachineConfigSpec->new(
        name         => $name,
        memoryMB     => '512',
        files        => $files,
        numCPUs      => 1,
        guestId      => 'winNetEnterpriseGuest',
        deviceChange => \@vm_devices
    );
    $folder->CreateVM( pool => $resource_pool, config => $config_spec );
    return 1;
}

sub create_test_entities {
    &VCenter::create_resource_pool( 'test_1337', 'Resources' );
    &VCenter::create_folder( 'test_1337', 'vm' );
    &VCenter::create_switch('test_1337');
    return 1;
}

sub uniq {
    return keys %{{ map { $_ => 1 } @_ }};
}

sub search_file {
    my ( $file, $string ) = @_;
    open( my $fh, "<", $file) or die $!;
    while ( my $line = <$fh> ) {
        if ( $line =~ /'$string'/ ) {
            return 1;
        }
    }
    return 0;
}

1
