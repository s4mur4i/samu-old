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
use File::Temp qw/tempfile/;

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
    my $view = Vim::find_entity_view(
        view_type  => 'VirtualMachine',
        properties => ['name'],
        filter     => { name => qr/^test_1337-/ }
    );
    ok( defined($view), "Cloned entity exists for $template" );
    my $name = $view->name;
    if ( &Support::get_key_value( 'template', $template, 'os' ) =~ /win/ ) {
        while ( &Guest::customization_status($name) !~ /Finished|Failed/ ) {
            sleep 15;
        }
    }
    my $hash = &Support::get_hash( 'template', $template );
    $view->update_view_data();
    if ( $view->{guest}->{toolsVersionStatus} ne 'guestToolsNotInstalled' ) {
        $view->update_view_data();
        if (    defined( $view->{guest} )
            and defined( $view->{guest}->{guestOperationsReady} ) )
        {
            while ( $view->{guest}->{guestOperationsReady} eq 0 ) {
                sleep 20;
                $view->update_view_data();
            }
        }
        sleep 25;
        my $guest_cred;
        eval {
            $guest_cred =
              &Guest::guest_cred( $name, $hash->{username}, $hash->{password} );
        };
        isa_ok( $guest_cred, 'NamePasswordAuthentication',
            "guest_cred returned object as expected" );
        my $num = int( rand(100) );
        my ( $fh, $filename ) = tempfile();
        print $fh $num;
        if ( $hash->{os}, 'win' ) {
            &Opts::add_options(
                %{ $entity::module_opts->{functions}->{run}->{opts} } );
            &Opts::set_option( "vmname",   $name );
            &Opts::set_option( "env",      "errorlevel=9" );
            &Opts::set_option( "workdir",  'C:' );
            &Opts::set_option( "prog",     "exit" );
            &Opts::set_option( "prog_arg", "/b %errorlevel%" );
            my ($pid) = &entity::run_command =~ /'(\d+)'$/;
            diag("pid is $pid");
            my $info = {
                vmname        => $name,
                guestusername => $hash->{username},
                guestpassword => $hash->{password},
                pid           => $pid
            };
            my $obj = &Guest::process_info($info);
            use Data::Dumper;
            diag( Dumper $obj);
            &Opts::add_options(
                %{ $entity::module_opts->{functions}->{transfer}->{opts} } );
            &Opts::set_option( "type",   "to" );
            &Opts::set_option( "vmname", $name );
            &Opts::set_option( "source", $filename );
            &Opts::set_option( "dest",   "to" );

        }
        else {

        }
        unlink $filename;
    }
    else {
        is( $hash->{os}, 'xcb', "Template is a XCB product" );
    }
    &Opts::add_options(
        %{
            $entity::module_opts->{functions}->{delete}->{functions}->{entity}
              ->{opts}
        }
    );
    &Opts::set_option( "type", "VirtualMachine" );
    &Opts::set_option( "name", $view->name );
    is( &entity::delete_entity(), 1, "Destroy vm sub ran succesfully" );
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
