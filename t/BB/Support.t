#!/usr/bin/perl
use strict;
use warnings;
use 5.14.0;
use Test::More;
use Test::Exception;
use FindBin;
use lib "$FindBin::Bin/../../lib";

BEGIN {
    use_ok('BB::Support');
    use_ok('BB::Common');
    &Opts::parse();
    &Opts::validate();
    &Util::connect();
    my $view = Vim::find_entity_view(
        view_type  => 'ResourcePool',
        properties => ['name'],
        filter     => { name => 'test_1337' }
    );
    if ( defined($view) ) {
        diag("ResourcePool exists");
        plan( skip_all =>
              "test_1337 ResourcePool exists. Delete it before test can be run"
        );
    }

}
ok( ref( &Support::get_keys("agents") ) eq 'ARRAY', 'get_keys returned array' );
throws_ok { &Support::get_keys('TEST') } 'Template::Status',
  'get_keys throws exception';

ok( ref( &Support::get_key_info( 'template', 'scb_342' ) ) eq 'HASH',
    'get_key_info returned hash' );
throws_ok { &Support::get_key_info( 'TEST', 'TEST' ) } 'Template::Status',
  'get_key_info throws exception for bad map';
throws_ok { &Support::get_key_info( 'template', 'TEST' ) } 'Template::Status',
  'get_key_info throws exception for bad key';

ok( ref( \&Support::get_key_value( 'agents', 's4mur4i', 'mac' ) ) eq 'SCALAR',
    'get_key_value returned scalar' );
throws_ok { &Support::get_key_value( 'TEST', 'TEST', 'TEST' ) }
'Template::Status', 'get_key_value throws exception for bad map';
throws_ok { &Support::get_key_value( 'agents', 'TEST', 'TEST' ) }
'Template::Status', 'get_key_value throws exception for bad key';
throws_ok { &Support::get_key_value( 'agents', 's4mur4i', 'TEST' ) }
'Template::Status', 'get_key_value throws exception for bad value';
ok( \&VCenter::create_resource_pool( 'test_1337', 'Resources' ),
    "Creating test_1337 resourcepool" );

for my $os_temp ( @{ &Support::get_keys("template") } ) {
    diag("Going to use $os_temp as test template");
    my $snapshot_config = VirtualMachineConfigInfo->new(
        alternateGuestName => 'test',
        changeVersion      => 'test',
        defaultPowerOps    => VirtualMachineDefaultPowerOpInfo->new(),
        files              => VirtualMachineFileInfo->new(),
        flags              => VirtualMachineFlagInfo->new(),
        guestFullName      => 'test',
        guestId            => 'test',
        hardware => VirtualHardware->new( memoryMB => 512, numCPU => 1 ),
        name     => 'test',
        modified => '1970-01-01T00:00:00Z',
        template => 1,
        uuid     => '12345678-abcd-1234-cdef-123456789abc',
        version  => '1'
    );
    my $snapshot_view =
      VirtualMachineSnapshot->new( config => $snapshot_config );
    isa_ok( &Support::RelocateSpec('test_1337'),
        'VirtualMachineRelocateSpec',
        "RelocateSpec returned VirtualMachineRelocateSpec object" );
    isa_ok( &Support::ConfigSpec( 512, 1, $os_temp ),
        'VirtualMachineConfigSpec',
        "ConfigSpec returned VirtualMachineConfigSpec object" );
    isa_ok( &Support::CustomizationPassword,
        'CustomizationPassword',
        "CustomizationPassword returned CustomizationPassword object" );
    isa_ok( &Support::identification_domain,
        'CustomizationIdentification',
        "identification_domain returned CustomizationIdentification object" );
    isa_ok( &Support::identification_workgroup, 'CustomizationIdentification',
        "identification_workgroup returned CustomizationIdentification object"
    );
    isa_ok(
        &Support::win_CloneSpec(
            "T_$os_temp", $snapshot_view,
            &Support::RelocateSpec('test_1337'),
            &Support::ConfigSpec( 512, 1, $os_temp ),
            0, 1
        ),
        'VirtualMachineCloneSpec',
        "win_CloneSpec returns VirtualMachineCloneSpec object for workgroup"
    );
    isa_ok(
        &Support::win_CloneSpec(
            "T_$os_temp", $snapshot_view,
            &Support::RelocateSpec('test_1337'),
            &Support::ConfigSpec( 512, 1, $os_temp ),
            1, 1
        ),
        'VirtualMachineCloneSpec',
        "win_CloneSpec returns VirtualMachineCloneSpec object for domain"
    );
    isa_ok(
        &Support::lin_CloneSpec(
            "T_$os_temp",
            $snapshot_view,
            &Support::RelocateSpec('test_1337'),
            &Support::ConfigSpec( 512, 1, $os_temp )
        ),
        'VirtualMachineCloneSpec',
        "lin_CloneSpec returned VirtualMachineCloneSpec object"
    );
    isa_ok(
        &Support::oth_CloneSpec(
            $snapshot_view,
            &Support::RelocateSpec('test_1337'),
            &Support::ConfigSpec( 512, 1, $os_temp )
        ),
        'VirtualMachineCloneSpec',
        "oth_CloneSpec returned VirtualMachineCloneSpec object"
    );
    diag("Check network settings");
    my @networks = &Guest::generate_network_setup($os_temp);

    for my $network (@networks) {
        isa_ok( $network, 'VirtualDeviceConfigSpec',
            "Interface is a valid ETHERNET object" );
    }
    my $os_temp_path = &Support::get_key_value( 'template', $os_temp, 'path' );
    my $os_temp_view =
      &VCenter::moref2view( &VCenter::path2moref($os_temp_path) );
    my @adapters =
      &Guest::CustomizationAdapterMapping_generator( $os_temp_view->name );
    for my $adapter (@adapters) {
        isa_ok( $adapter, 'CustomizationAdapterMapping',
            "Adapter is a valid customization mapping adapter" );
    }
    my @interfaces = &Guest::network_interfaces( $os_temp_view->name );
    for my $interface (@interfaces) {
        isa_ok( $interface, 'HASH', "Network interface returned is a hash" );
    }
}
done_testing;

END {
    my $view = &Guest::entity_name_view( 'test_1337', 'ResourcePool' );
    $view->Destroy;
    &Util::disconnect;
}
