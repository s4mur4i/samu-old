#!/usr/bin/perl
use strict;
use warnings;
use 5.14.0;
use Test::More;
use Test::Output;
use Test::Exception;
use FindBin;
use lib "$FindBin::Bin/../../lib/";
use lib "$FindBin::Bin/../../vmware_lib/";
use BB::Common;

BEGIN {
    &Opts::add_options();
    &Opts::parse();
    &Opts::validate();
    &Util::connect();
    my $view = Vim::find_entity_view( view_type => 'VirtualMachine', properties => [ 'name' ], filter => { name => qr/^test_1337-/ } );
    if ( defined( $view ) ) {
        plan( skip_all => "test_1337 VirtualMachine exists. Delete it before test can be run" );
    }
}
diag("Test snapshot functions");
&Util::connect();
&VCenter::create_test_entities;
&VCenter::create_test_vm( 'test_1337' );
my $view = Vim::find_entity_views( view_type => 'VirtualMachine', properties => [ 'name', 'snapshot' ], filter => { name => qr/^test_1337/ } );
ok( scalar(@$view) eq 1, "There is only one entity for snapshot test" );
$view= $$view[0];
is( exists $view->{snapshot}, '', "There are no snapshots on vm" );
throws_ok { &Guest::list_snapshot( $view->name ) } 'Entity::Snapshot', "list snapshot returns 1 for succesful run";
is( &Guest::create_snapshot( $view->name, 'test', 'test' ), 1, "Create snapshot was succesful" );
$view->update_view_data();
stderr_like(  sub { &Guest::traverse_snapshot( $view->snapshot->rootSnapshotList->[0], $view->snapshot->currentSnapshot->value ) }, qr/^\*CUR\* ID=> '1', name=> 'test', creationTime=>'[^']*', description=>'test';$/, qr/^$/, "traverse snapshot returns one snapshot" );
is( &Guest::traverse_snapshot( $view->snapshot->rootSnapshotList->[0], $view->snapshot->currentSnapshot->value ), 0, "Traverse snapshot returned 0" );
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
