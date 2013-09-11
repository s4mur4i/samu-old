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
use Data::Dumper;

diag("Test cloning functions");
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
throws_ok { &entity::clone_vm; } 'Template::Status', 'Incorrect template throws Exception';
for my $template ( @{&Support::get_keys( 'template' )} ) {
    diag("Testing template: $template");
    &Opts::set_option("os_temp", $template);
    ok( &entity::clone_vm eq 1, "Template was cloned succesfully" );
    my $view = Vim::find_entity_view( view_type => 'VirtualMachine', properties => [ 'name' ], filter => { name => qr/^test_1337-/ } );
    ok( defined($view), "Cloned entity exists for $template" );
    $view->PowerOffVM;
    $view->Destroy;
    $view = Vim::find_entity_view( view_type => 'VirtualMachine', properties => [ 'name' ], filter => { name => qr/^test_1337-/ } );
    ok( !defined($view), "Cloned entity Destroyed succesfully" );
}
my $resource_pool_view = Vim::find_entity_view( view_type => 'VirtualMachine', properties => [ 'name' ], filter => { name => qr/^test_1337-/ } );
$resource_pool_view->Destroy;
&Util::disconnect();
done_testing;
