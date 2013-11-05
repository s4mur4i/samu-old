#!/usr/bin/perl
use strict;
use warnings;
use 5.14.0;
use Test::More;
use Test::Exception;
use Test::Output;
use FindBin;
use lib "$FindBin::Bin/../../lib/";
use lib "$FindBin::Bin/../../vmware_lib/";
use BB::Common;
use Base::entity;

BEGIN {
    &Opts::add_options(
        %{ $entity::module_opts->{functions}->{clone}->{opts} } );
    &Opts::parse();
    &Opts::set_option( "ticket",  "test_1337" );
    &Opts::set_option( "os_temp", "test" );
    &Opts::validate();
    &Util::connect();
    my $view = Vim::find_entity_view(
        view_type  => 'VirtualMachine',
        properties => ['name'],
        filter     => { name => qr/^test_1337-/ }
    );
    if ( defined($view) ) {
        plan( skip_all =>
"test_1337 VirtualMachine exists. Delete it before test can be run"
        );
    }
}
if ( not( $ENV{ALL} or $ENV{TEMPLATE} ) ) {
    my $msg = 'Author test.  Set $ENV{TEMPLATE} to a true value to run.';
    plan( skip_all => $msg );
}

ok( \&VCenter::create_resource_pool( 'test_1337', 'Resources' ),
    "Creating test_1337 resourcepool" );

diag("Test cloning functions");
for my $template ( @{ &Support::get_keys('template') } ) {
    diag("Testing template: $template");
    &Opts::set_option( "os_temp", $template );
    ok( &entity::clone_vm eq 1, "Template was cloned succesfully" );
    my $view = Vim::find_entity_view( view_type  => 'VirtualMachine', properties => ['name'], filter     => { name => qr/^test_1337-/ });
    ok( defined($view), "Cloned entity exists for $template" );
    $view->PowerOffVM;
    diag("Testing list functions");
    my $name = $view->name;
    diag("Name is $name");
    &Opts::add_options( %{ $entity::module_opts->{functions}->{list}->{functions}->{disk} ->{opts} });
    &Opts::set_option( "noheader", 1 );
    &Opts::set_option( "vmname", $name );
    output_like( \&entity::list_disk, qr/^\s*0\s*\d+\s*\d+\s\[support\] $name\/$name.vmdk\s*$/, qr/^$/, "Listing disk information");
    output_like( \&entity::list_cdrom, qr/^\s*0\s*\d+\s*Client_Device\s*CD\/DVD drive 1\s*/, qr/^$/, "Listing cdrom information");
    output_like( \&entity::list_interface, qr/^\s*0\s*\d+\s*([0-9A-F]{2}:){5}[0-9A-F]{2}\s*Network adapter 1\s*VLAN21\s\S*\s*$/, qr/^$/, "Listing network information");
    throws_ok { &entity::list_snapshot() } 'Entity::Snapshot', "list_snapshot throws exception";
    diag("Testing add functions");
    for ( my $i = 1; $i< 4; $i++ ) {
        is( &entity::add_cdrom, 1, "Add cdrom $i returned success" );
    }
    is( scalar( @{ &Guest::get_hw( $name, 'VirtualCdrom' ) } ), '4', "There are 4 cdroms on machine" );
    throws_ok { &entity::add_cdrom } 'Entity::HWError', "Add cdrom throws exception if no free controller is found";
    &Opts::add_options( %{ $entity::module_opts->{functions}->{add}->{functions}->{disk} ->{opts} });
    &Opts::set_option( "size", "1" );
    for ( my $i = 1; $i< 14; $i++ ) {
        is( &entity::add_disk, 1, "Add disk $i returned success" );
    }
    is( scalar( @{ &Guest::get_hw( $name, 'VirtualDisk' ) } ), '14', "There are 14 disks in machine" );
    throws_ok { &entity::add_disk } 'Entity::HWError', "Add disk throws exception if no free scsi controller is found";
    &Opts::add_options( %{ $entity::module_opts->{functions}->{add}->{functions}->{interface} ->{opts} });
    my $cur_int = scalar( @{ &Guest::get_hw( $name, 'VirtualEthernetCard' ) } );
    &Opts::set_option( "type", "E1000" );
    is( &entity::add_interface, 1, "Add interface returned success" );
    is( scalar( @{ &Guest::get_hw( $name, 'VirtualEthernetCard' ) } ), ++$cur_int, "A new interface has been added" );
    &Opts::set_option( "type", "Vmxnet" );
    is( &entity::add_interface, 1, "Add interface returned success" );
    is( scalar( @{ &Guest::get_hw( $name, 'VirtualEthernetCard' ) } ), ++$cur_int, "A 2nd interface has been added" );
    &Opts::set_option( "type", "Test" );
    throws_ok { &entity::add_disk } 'Entity::HWError', "Add disk throws exception if no free scsi controller is found";

    diag("Changing the HW");
    &Opts::add_options( %{ $entity::module_opts->{functions}->{change}->{functions}->{cdrom} ->{opts} });
    &Opts::set_option( "num", "0" );
    &Opts::set_option( "iso", "[share] Linux/clonezilla-live-1.2.8-23-amd64.iso" );
    is( &entity::change_cdrom, 1, "Can change the cdrom to the linux vmware tools");
    &Opts::add_options( %{ $entity::module_opts->{functions}->{list}->{functions}->{disk} ->{opts} });
    &Opts::set_option( "noheader", 1 );
    output_like( \&entity::list_cdrom, qr/^\s*0\s*\d+\s*\[share\]\sLinux\/clonezilla-live-1\.2\.8-23-amd64\.iso\s*CD\/DVD drive \d+\s*/, qr/^$/, "Listing cdrom information");
    &Opts::add_options( %{ $entity::module_opts->{functions}->{change}->{functions}->{cdrom} ->{opts} });
    &Opts::set_option( "num", "0" );
    &Opts::set_option( "vmname", $name );
    &Opts::set_option( "unmount", "0" );
    &Opts::set_option( "iso", 0 );
    throws_ok { &entity::change_cdrom } 'Vcenter::Opts', "Exception is thrown if no option is specified";
    &Opts::set_option( "unmount", "1" );
    &Opts::set_option( "iso", "[support] RingDing/Ring" );
    throws_ok { &entity::change_cdrom } 'Vcenter::Opts', "Exception is thrown if both unmount and iso is specified";
    &Opts::set_option( "unmount", "0" );
    throws_ok { &entity::change_cdrom } 'Vcenter::Path', "Exception is thrown if no file can be found with datastore";
    &Opts::set_option( "iso", 0 );
    &Opts::set_option( "unmount", "1" );
    is( &entity::change_cdrom, 1, "Can unmount the cdrom");
    &Opts::add_options( %{ $entity::module_opts->{functions}->{list}->{functions}->{disk} ->{opts} });
    &Opts::set_option( "noheader", 1 );
    output_like( \&entity::list_cdrom, qr/^\s*0\s*\d+\s*Client_Device\s*CD\/DVD drive \d+\s*/, qr/^$/, "Listing cdrom information");

    &Opts::add_options( %{ $entity::module_opts->{functions}->{change}->{functions}->{interface}->{opts} });
    &Opts::set_option( "num", "0" );
    &Opts::set_option( "vmname", $name );
    &Opts::set_option( "network", "Internal Network 1" );
    is( &entity::change_interface, 1, "Change interface is succesful");
    output_like( \&entity::list_interface, qr/^\s*0\s*\d+\s*([0-9A-F]{2}:){5}[0-9A-F]{2}\sNetwork\sadapter\s\d\sInternal\sNetwork\s1\s[^ ]*/, qr/^$/, "Listing network information");
    &Opts::set_option( "network", "TestTestTest1234" );
    throws_ok{ &entity::change_interface} 'Entity::NumException', "Unknown Network throws exception";
    &Opts::set_option( "num", "9" );
    throws_ok{ &entity::change_interface} 'Entity::HWError', "Higher interface count throws exception";


    diag("Deleting HW");
    &Opts::add_options( %{ $entity::module_opts->{functions}->{delete}->{functions}->{hw} ->{opts} });
    &Opts::set_option( "hw", "cdrom" );
    &Opts::set_option( "id", "0" );
    for ( my $i = 0; $i<4; $i++) {
        is( &entity::delete_hw, 1, "Deleting cdrom $i" );
    }
    throws_ok { &entity::delete_hw } 'Entity::HWError', "Delete hw throughs exception if no more hardware is found for cdrom";
    &Opts::set_option( "hw", "disk" );
    for ( my $i = 0; $i<14; $i++) {
        is( &entity::delete_hw, 1, "Deleting disk $i" );
    }
    throws_ok { &entity::delete_hw } 'Entity::HWError', "Delete hw throughs exception if no more hardware is found for disk";
    &Opts::set_option( "hw", "interface" );
    for ( my $i = 0; $i<3; $i++) {
        is( &entity::delete_hw, 1, "Deleting interface $i" );
    }
    throws_ok { &entity::delete_hw } 'Entity::HWError', "Delete hw throughs exception if no more hardware is found for interface";
    &Opts::set_option( "hw", "test" );
    throws_ok { &entity::delete_hw } 'Vcenter::Opts', "Exception is thrown if unknown hardware is requested to be deleted";


    diag("Deleting entity");
    &Opts::add_options( %{ $entity::module_opts->{functions}->{delete}->{functions}->{entity} ->{opts} });
    &Opts::set_option( "type", "VirtualMachine" );
    &Opts::set_option( "name", $view->name );
    is( Opts::get_option('vmname'), $view->name, "Vmname option was set succesfully" );
    is( &entity::delete_entity(), 1, "Destroy vm sub ran succesfully" );
    $view = Vim::find_entity_view( view_type  => 'VirtualMachine', properties => ['name'], filter     => { name => qr/^test_1337-/ });
    ok( !defined($view), "Cloned entity Destroyed succesfully" );
    throws_ok { &entity::delete_entity() } 'Entity::NumException',
      "Destroy vm throws exception if no vm is present";
}
done_testing;

END {
    my @types = ( 'VirtualMachine', 'ResourcePool', 'Folder',
        'DistributedVirtualSwitch' );
    for my $type (@types) {
        my $view = Vim::find_entity_view(
            view_type  => $type,
            properties => ['name'],
            filter     => { name => qr/^test_1337/ }
        );
        if ( defined($view) ) {
            $view->Destroy;
        }
    }
    &Util::disconnect();
}
