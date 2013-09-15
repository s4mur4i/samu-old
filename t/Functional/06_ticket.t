#!/usr/bin/perl
use strict;
use warnings;
use 5.14.0;
use Test::More;
use Test::Exception;
use FindBin;
use lib "$FindBin::Bin/../../lib/";
use lib "$FindBin::Bin/../../vmware_lib/";
use BB::Common;
use Base::entity;

BEGIN {
    &Opts::add_options();
    &Opts::parse();
    &Opts::validate();
    &Util::connect();
    my @types = qw(VirtualMachine ResourcePool DistributedVirtualSwitch Folder);
    for my $type ( @types ) {
        my $view = Vim::find_entity_view( view_type => $type, properties => [ 'name' ], filter => { name => qr/^test_1337/ } );
        if ( defined( $view ) ) {
            plan( skip_all => "test_1337 $type exists. Delete it before test can be run" );
        }
    }
    &VCenter::create_test_entities;
}
my @types = qw(VirtualMachine ResourcePool DistributedVirtualSwitch Folder);
diag("Test ticket functions");
throws_ok { &VCenter::create_resource_pool( 'test_1337', 'Resources' ) } 'Entity::NumException', 'Same name resource cannot be created twice';
throws_ok { &VCenter::create_resource_pool( 'test_1337', 'Resources2' ) } 'Entity::NumException', 'Exception is thrown if no parent exists';
throws_ok { &VCenter::create_folder( 'test_1337', 'vm' ) } 'Entity::NumException', 'Same name folder cannot be created twice';
throws_ok { &VCenter::create_folder( 'test_1337', 'vm2' ) } 'Entity::NumException', 'Exception is thrown if no parent exists';
throws_ok { &VCenter::create_switch( 'test_1337' ) } 'Entity::NumException', 'Same name switch cannot be created twice';
&VCenter::create_test_vm( 'test_1337-test-test_test-123' );
my $vmname = &VCenter::ticket_vms_name( 'test_1337' );
is( scalar(@$vmname), 1, "ticket_vms_name returned one name" );
like( $$vmname[0], qr/^test_1337-[^-]*-[^-]*-\d{1,3}/, "ticket_vms_name is a valid vmname" );

diag("Powering on VM");
is( &Guest::poweron($$vmname[0]), 1, "Powering on VM" );
my $view = Vim::find_entity_view( view_type => 'VirtualMachine', properties => [ 'runtime.powerState' ], filter => { name => $$vmname[0] } );
my $powerstate = $view->get_property('runtime.powerState');
ok( $powerstate->val eq 'poweredOn', "Guest is powered on" );

diag("Powering off VM");
is( &Guest::poweroff($$vmname[0]), 1, "Powering off VM" );
$view = Vim::find_entity_view( view_type => 'VirtualMachine', properties => [ 'name', 'runtime.powerState' ], filter => { name => $$vmname[0] } );
$powerstate = $view->get_property('runtime.powerState');
ok( $powerstate->val eq 'poweredOff', "Guest is powered off" );
diag("Generating ticket list");
my $list = &Misc::ticket_list;
ok( defined($list->{test_1337}), "Test ticket is returned from ticket_list sub" );
diag("Test num_check sub");
throws_ok { &VCenter::num_check( 'test_1337_test_1337', 'VirtualMachine' ) } 'Entity::NumException', 'Num_check throws exception';
is( &VCenter::num_check( $view->name, 'VirtualMachine' ), 1, "Num_check finds only one entity for Vm" );
is( &VCenter::exists_entity( $view->name, 'VirtualMachine' ), 1, "Exists entity returns true for found VM" );
diag("Testing path2view");
my $path = &VCenter::name2path( $view->name );
my $view2 = &VCenter::moref2view( &VCenter::path2moref( $path ) );
is( $view->name, $view2->name, "Normal VM object and returned objects are same" );
for my $type ( @types ) {
    diag("Destroying test $type");
    my $view = Vim::find_entity_view( view_type => $type, properties => [ 'name' ], filter => { name => qr/^test_1337/ } );
    $view->Destroy;
}
is( &VCenter::exists_entity( $view->name, 'VirtualMachine' ), 0, "Exists entity returns false for no VM" );
done_testing;
END {
    my @types = ( 'VirtualMachine', 'ResourcePool', 'Folder', 'DistributedVirtualSwitch' );
    for my $type ( @types ) {
        my $view = Vim::find_entity_view( view_type => $type, properties => [ 'name' ], filter => { name => qr/^test_1337/ } );
        if ( defined( $view ) ) {
            $view->Destroy;
        }
    }
    &Util::disconnect();
}
