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

diag("Test ticket functions");
&Opts::add_options();
&Opts::parse();
&Opts::validate();
&Util::connect();
my @types = qw(VirtualMachine ResourcePool DistributedVirtualSwitch Folder);
for my $type ( @types ) {
    my $view = Vim::find_entity_view( view_type => $type, properties => [ 'name' ], filter => { name => qr/^test_1337-/ } );
    if ( defined( $view ) ) {
        plan( skip_all => "test_1337 $type exists. Delete it before test can be run" );
    }
}
ok( scalar(&VCenter::ticket_vms_name( 'test_1337' )) eq 1, "ticket_vms_name returned one name" );
my @vmname = &VCenter::ticket_vms_name( 'test_1337' );
like( $vmname[0], qr/^test_1337_[^-]*-[^-]*-\d{1,3}/, "ticket_vms_name is a valid vmname" );

diag("Powering on VM");
ok( &Guest::poweron($vmname[0]), "Powering on VM" );
my $view = Vim::find_entity_view( view_type => 'VirtualMachine', properties => [ 'runtime.powerState' ], filter => { name => $vmname[0] } );
my $powerstate = $view->get_property('runtime.powerState');
ok( $powerstate->val eq 'poweredOn', "Guest is powered on" );

diag("Powering off VM");
ok( &Guest::poweroff($vmname[0]), "Powering off VM" );
$view = Vim::find_entity_view( view_type => 'VirtualMachine', properties => [ 'runtime.powerState' ], filter => { name => $vmname[0] } );
$powerstate = $view->get_property('runtime.powerState');
ok( $powerstate->val eq 'poweredOff', "Guest is powered off" );
for my $type ( @types ) {
    my $view = Vim::find_entity_view( view_type => $type, properties => [ 'name' ], filter => { name => qr/^test_1337-/ } );
    $view->Destroy;
}
&Util::disconnect();
done_testing;
