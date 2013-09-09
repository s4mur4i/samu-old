#!/usr/bin/perl
use strict;
use warnings;
use 5.14.0;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../../lib/";
use lib "$FindBin::Bin/../../lib2/";
use BB::Common;
use Base::admin;

sub create_entities {
    ok( \&VCenter::create_resource_pool( 'test_1337', 'Resources' ), "Creating test_1337 resourcepool" );
    ok( \&VCenter::create_folder( 'test_1337', 'vm' ), "Creating test_1337 folder" );
    #ok( \&VCenter::create_resource_pool( 'test_1337', 'Resources' ), "Creating test_1337 DVS" );
}

diag("Check if any entity exists for our test_1337 ticket");
#my @types = ( 'ResourcePool', 'Folder', 'DistributedVirtualSwitch' );
my @types = ( 'ResourcePool', 'Folder');
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
&create_entities;
for my $type ( @types ) {
    my $ret = &VCenter::check_if_empty_entity( 'test_1337', $type );
    is( $ret , 1, "Check if empty returned true for empty $type" );
    ok( \&VCenter::destroy_entity( 'test_1337', $type ), "Destroying test_1337 $type" );
    is( Vim::find_entity_view( view_type =>$type, properties => [ 'name' ], filter => { name => 'test_1337' } ), undef, "test_1337 $type doesn't exist after delete" );
}
&create_entities;
is( &admin::cleanup, '' ,"Admin cleanup sub deletes resource Pool" );
for my $type ( @types ) {
    is( Vim::find_entity_view( view_type =>$type, properties => [ 'name' ], filter => { name => 'test_1337' } ), undef, "test_1337 $type doesn't exist after cleanup" );
}
&Util::disconnect();
done_testing;
