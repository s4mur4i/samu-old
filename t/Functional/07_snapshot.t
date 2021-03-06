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
use SAMU_Test::Common;
use Base::entity;

BEGIN {
    &Opts::add_options( %{ $entity::module_opts->{functions}->{add}->{functions}->{snapshot} ->{opts} });
    &Opts::parse();
    &Opts::set_option( "vmname", "test_1337" );
    &Opts::validate();
    &Util::connect();
    &Test::cleanup_test;
    my $view = Vim::find_entity_view( view_type  => 'VirtualMachine', properties => ['name'], filter     => { name => qr/^test_1337-/ });
    if ( defined($view) ) {
        plan( skip_all => "test_1337 VirtualMachine exists. Delete it before test can be run");
    }
}
diag("Test snapshot functions");

#&Util::connect();
&Test::create_test_entities;
&Test::create_test_vm('test_1337');
my $view = Vim::find_entity_views( view_type  => 'VirtualMachine', properties => [ 'name', 'snapshot' ], filter     => { name => qr/^test_1337/ });
ok( scalar(@$view) eq 1, "There is only one entity for snapshot test" );
$view = $$view[0];
is( exists $view->{snapshot}, '', "There are no snapshots on vm" );
&Opts::add_options( %{ $entity::module_opts->{functions}->{list}->{functions}->{snapshot} ->{opts} });
&Opts::set_option('vmname', $view->{name});
&Opts::set_option('noheader', 1);
throws_ok { &entity::list_snapshot } 'Entity::Snapshot', "list snapshot returns Exception when no snapshot present";
is( &Guest::create_snapshot( $view->name, 'test', 'test' ), 1, "Create 1st snapshot was succesful" );
#$view->update_view_data();
output_like( sub{ &entity::list_snapshot }, qr/^CUR\s1\stest\s[^ ]*\stest$/, qr/^$/, "List snapshot output is correct on stdout and stderr");
is( &entity::add_snapshot(), 1, "Create 2nd snapshot was succesful" );
output_like( sub{ &entity::list_snapshot}, qr/^---\s1\stest\s[^ ]*\stest/, qr/^$/, "List snapshot output is correct on stdout and stderr");
&Opts::add_options( %{ $entity::module_opts->{functions}->{change}->{functions}->{snapshot} ->{opts} });
&Opts::set_option( "id", "1" );
is( &entity::change_snapshot(), 1, "Revert to snapshot was succesfull" );
output_like( sub{ &entity::list_snapshot}, qr/^CUR\s1\stest\s[^ ]*\stest/, qr/^$/, "List snapshot output is correct on stdout and stderr");
&Opts::add_options( %{ $entity::module_opts->{functions}->{delete}->{functions}->{snapshot} ->{opts} });
&Opts::set_option( "id",  "0" );
&Opts::set_option( "all", "1" );
is( &entity::delete_snapshot(), 1, "Delete All snapshots was succesful" );
throws_ok { &entity::list_snapshot() } 'Entity::Snapshot', "list_snapshot throws exception when no snapshot is present";
is( &entity::add_snapshot(), 1, "Create 3nd snapshot was succesful" );
output_like( sub{ &entity::list_snapshot}, qr/^CUR\s3\ssnap/, qr/^$/, "List snapshot output is correct on stdout and stderr");
&Opts::set_option( "all", "0" );
&Opts::set_option( "id",  "3" );
is( &entity::delete_snapshot(), 1, "Delete snapshot 3 was succesful" );
throws_ok { &entity::list_snapshot() } 'Entity::Snapshot', "list_snapshot throws exception when no snapshot is present";
done_testing;

END {
    &Test::cleanup_test;
    &Util::disconnect();
}
