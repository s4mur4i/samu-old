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

SKIP: {
    eval { ( not( $ENV{ALL} or $ENV{TEMPLATE_HASH} ) ) and die "Need to skip" };

    diag("Test cloning functions");
    throws_ok { &entity::clone_vm; } 'Template::Status', 'Incorrect template throws Exception';
    for my $template ( @{ &Support::get_keys('template') } ) {
        diag("Testing template: $template");
        &Opts::set_option( "os_temp", $template );
        ok( &entity::clone_vm eq 1, "Template was cloned succesfully" );
        my $view = Vim::find_entity_view( view_type  => 'VirtualMachine', properties => ['name'], filter     => { name => qr/^test_1337-/ });
        ok( defined($view), "Cloned entity exists for $template" );
        $view->PowerOffVM;
        diag("Testing altername");
        &Opts::add_options( %{ $entity::module_opts->{functions}->{list}->{functions}->{disk} ->{opts} });
        &Opts::set_option( "vmname", $view->name );
        is( &Guest::get_altername( $view->name ), '', "Altername is default for " . $view->name );
        like( &Guest::get_annotation_key( $view->name, "alternateName" ), qr/^\d+$/, "Annotation_key returns digit" );
        is( &Guest::change_altername( $view->name, "pina" ), 1, "Altername is set for " . $view->name );
        is( &Guest::get_altername( $view->name ), 'pina', "Altername is changed for " . $view->name );
        diag("Deleting entity");
        &Opts::add_options( %{ $entity::module_opts->{functions}->{delete}->{functions}->{entity} ->{opts} });
        &Opts::set_option( "type", "VirtualMachine" );
        &Opts::set_option( "name", $view->name );
        is( Opts::get_option('vmname'), $view->name, "Vmname option was set succesfully" );
        is( &entity::delete_entity(), 1, "Destroy vm sub ran succesfully" );
        $view = Vim::find_entity_view( view_type  => 'VirtualMachine', properties => ['name'], filter     => { name => qr/^test_1337-/ });
        ok( !defined($view), "Cloned entity Destroyed succesfully" );
        throws_ok { &entity::delete_entity() } 'Entity::NumException', "Destroy vm throws exception if no vm is present";
    }
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
