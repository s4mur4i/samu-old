#!/usr/bin/perl
use strict;
use warnings;
use 5.14.0;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../../lib/";
use lib "$FindBin::Bin/../../vmware_lib/";
use BB::Common;
use Base::admin;

diag("Check if any entity exists for our test_1337 ticket");
my @types = ( 'ResourcePool', 'Folder', 'DistributedVirtualSwitch' );
&Opts::parse();
&Opts::validate();
&Util::connect();
is( &admin::cleanup, '',"Admin cleanup sub ran succesfully" );
for my $type ( @types ) {
    my $view = Vim::find_entity_view( view_type => $type, properties => [ 'name' ], filter => { name => 'test_1337' } );
    if ( defined( $view ) ) {
        diag("$type exists");
        plan( skip_all => "test_1337 $type exists. Delete it before test can be run" );
    }
}
diag("Creating empty resources and calling backend subs");
&VCenter::create_entities;
for my $type ( @types ) {
    my $ret = &VCenter::check_if_empty_entity( 'test_1337', $type );
    is( $ret , 1, "Check if empty returned true for empty $type" );
    ok( \&VCenter::destroy_entity( 'test_1337', $type ), "Destroying test_1337 $type" );
    is( Vim::find_entity_view( view_type =>$type, properties => [ 'name' ], filter => { name => 'test_1337' } ), undef, "test_1337 $type doesn't exist after delete" );
}
diag("Creating resources and calling cleanup to see if deleted");
&VCenter::create_entities;
is( &admin::cleanup, '' ,"Admin cleanup sub deletes resource Pool" );
for my $type ( @types ) {
    is( Vim::find_entity_view( view_type =>$type, properties => [ 'name' ], filter => { name => 'test_1337' } ), undef, "test_1337 $type doesn't exist after cleanup" );
}
diag("Creating resources with entity and see if they don't get deleted");
&VCenter::create_entities;
ok( \&VCenter::create_dvportgroup( 'test_1337_dvg', 'test_1337' ), "Creating test_1337_dvg DVPG");
&VCenter::create_test_vm( 'test_1337' );
&admin::cleanup;
for my $type ( @types ) {
    is( &VCenter::exists_entity( 'test_1337', $type ), 1, "Entity Exists $type" );
}
diag("Delete entity and run cleanup again to see if deleted");
my $view = &Guest::entity_name_view( 'test_1337', 'VirtualMachine' );
my $task = $view->Destroy_Task;
&VCenter::Task_Status( $task );
$view = &Guest::entity_name_view( 'test_1337_dvg', 'DistributedVirtualPortgroup' );
$task = $view->Destroy_Task;
&VCenter::Task_Status( $task );
&admin::cleanup;
for my $type ( @types ) {
    is( Vim::find_entity_view( view_type =>$type, properties => [ 'name' ], filter => { name => 'test_1337' } ), undef, "test_1337 $type doesn't exist after cleanup" );
}
&Util::disconnect();
done_testing;
