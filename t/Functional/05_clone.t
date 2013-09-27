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
    &Opts::add_options(%{$entity::module_opts->{functions}->{clone}->{opts}});
    &Opts::parse();
    &Opts::set_option("ticket", "test_1337");
    &Opts::set_option("os_temp", "test");
    &Opts::validate();
    &Util::connect();
    my $view = Vim::find_entity_view( view_type => 'VirtualMachine', properties => [ 'name' ], filter => { name => qr/^test_1337-/ } );
    if ( defined( $view ) ) {
        plan( skip_all => "test_1337 VirtualMachine exists. Delete it before test can be run" );
    }
}
diag("Test cloning functions");
throws_ok { &entity::clone_vm; } 'Template::Status', 'Incorrect template throws Exception';
for my $template ( @{&Support::get_keys( 'template' )} ) {
    diag("Testing template: $template");
    &Opts::set_option("os_temp", $template);
    ok( &entity::clone_vm eq 1, "Template was cloned succesfully" );
    my $view = Vim::find_entity_view( view_type => 'VirtualMachine', properties => [ 'name' ], filter => { name => qr/^test_1337-/ } );
    ok( defined($view), "Cloned entity exists for $template" );
    $view->PowerOffVM;
    diag("Testing altername");
    &Opts::add_options(%{$entity::module_opts->{functions}->{list}->{functions}->{disk}->{opts}});
    &Opts::set_option("vmname", $view->name);
    is( &Guest::get_altername($view->name), '', "Altername is default for " . $view->name );
    like( &Guest::get_annotation_key( $view->name, "alternateName" ), qr/^\d+$/, "Annotation_key returns digit" );
    is( &Guest::change_altername($view->name, "pina"), 1, "Altername is set for " . $view->name );
    is( &Guest::get_altername($view->name), 'pina', "Altername is changed for " . $view->name );
    diag("Testing list functions");
    my $name = $view->name;
    output_like(  \&entity::list_disk, qr/^number=>'0',\skey=>'\d+',\ssize=>'\d+'\sKB,\spath=>'\[support\] $name\/$name.vmdk'$/, qr/^$/, "Listing disk information" );
    output_like(  \&entity::list_cdrom, qr/^number=>'0', key=>'\d+', backing=>'Client Device', label=>'[^']*'$/, qr/^$/, "Listing cdrom information" );
    output_like(  \&entity::list_interface, qr/^number=>'0', key=>'\d+', mac=>'([0-9A-F]{2}:){5}[0-9A-F]{2}', interface=>'[^']*', type=>'[^']*', label=>'Network adapter 1'/, qr/^$/, "Listing network information" );
    throws_ok { &entity::list_snapshot( ) } 'Entity::Snapshot', "list_snapshot throws exception";
    diag("Testing add functions");
    is( &entity::add_cdrom, 1, "Add cdrom 2 returned success" );
    is( &entity::add_cdrom, 1, "Add cdrom 3 returned success" );
    is( &entity::add_cdrom, 1, "Add cdrom 4 returned success" );
    is( scalar(@{&Guest::get_hw( $name, 'VirtualCdrom')}), '4', "There are 4 cdroms on machine" );
    throws_ok { &entity::add_cdrom } 'Entity::HWError', "Add cdrom throws exception if no free controller is found";
    &Opts::add_options(%{$entity::module_opts->{functions}->{add}->{functions}->{disk}->{opts}});
    &Opts::set_option("size", "1");
    is( &entity::add_disk, 1, "Add disk 2 returned success" );
    is( &entity::add_disk, 1, "Add disk 3 returned success" );
    is( &entity::add_disk, 1, "Add disk 4 returned success" );
    is( &entity::add_disk, 1, "Add disk 5 returned success" );
    is( &entity::add_disk, 1, "Add disk 6 returned success" );
    is( &entity::add_disk, 1, "Add disk 7 returned success" );
    is( &entity::add_disk, 1, "Add disk 8 returned success" );
    is( &entity::add_disk, 1, "Add disk 9 returned success" );
    is( &entity::add_disk, 1, "Add disk 10 returned success" );
    is( &entity::add_disk, 1, "Add disk 11 returned success" );
    is( &entity::add_disk, 1, "Add disk 12 returned success" );
    is( &entity::add_disk, 1, "Add disk 13 returned success" );
    is( &entity::add_disk, 1, "Add disk 14 returned success" );
    is( scalar(@{ &Guest::get_hw( $name, 'VirtualDisk')}), '14', "There are 14 disks in machine" );
    throws_ok { &entity::add_disk } 'Entity::HWError', "Add disk throws exception if no free scsi controller is found";
    &Opts::add_options(%{$entity::module_opts->{functions}->{add}->{functions}->{interface}->{opts}});
    my $cur_int = scalar(@{ &Guest::get_hw( $name, 'VirtualEthernetCard')});
    &Opts::set_option("type", "E1000");
    is( &entity::add_interface, 1, "Add interface returned success" );
    is ( scalar(@{ &Guest::get_hw( $name, 'VirtualEthernetCard')}), ++$cur_int, "A new interface has been added" );
    &Opts::set_option("type", "Vmxnet");
    is( &entity::add_interface, 1, "Add interface returned success" );
    is ( scalar(@{ &Guest::get_hw( $name, 'VirtualEthernetCard')}), ++$cur_int, "A 2nd interface has been added" );
    &Opts::set_option("type", "Test");
    throws_ok { &entity::add_disk } 'Entity::HWError', "Add disk throws exception if no free scsi controller is found";

    diag("Deleting entity");
    &Opts::add_options(%{$entity::module_opts->{functions}->{delete}->{functions}->{vm}->{opts}});
    is( Opts::get_option('vmname'), $view->name, "Vmname option was set succesfully" );
    is( &entity::delete_vm(), 1, "Destroy vm sub ran succesfully" );
    $view = Vim::find_entity_view( view_type => 'VirtualMachine', properties => [ 'name' ], filter => { name => qr/^test_1337-/ } );
    ok( !defined($view), "Cloned entity Destroyed succesfully" );
    throws_ok { &entity::delete_vm() } 'Entity::NumException', "Destroy vm throws exception if no vm is present";
}
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
