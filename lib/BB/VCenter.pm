package VCenter;

use strict;
use warnings;
use Data::Dumper;

BEGIN {
    use Exporter;
    our @ISA    = qw( Exporter );
    our @EXPORT = qw( );
}

### Methods
#tested
sub clonevm {
    my ( $template, $vmname, $folder, $clone_spec ) = @_;
    &Log::debug(
        "Starting VCenter::clonevm sub, vmname=>'$vmname', folder=>'$folder'");
    &Log::dumpobj( "clone_spec", $clone_spec );
    my $template_view = &Guest::entity_name_view( $template, 'VirtualMachine' );
    &Log::debug2( "template_view", $template_view );
    my $folder_view = &Guest::entity_name_view( $folder, 'Folder' );
    &Log::dumpobj( "folder_view", $folder_view );
    &Log::info("Starting Clone task");
    my $task = $template_view->CloneVM_Task(
        folder => $folder_view,
        name   => $vmname,
        spec   => $clone_spec
    );
    &Log::dumpobj( "Task object:" . Dumper($task) );
    &Task_Status($task);
    &Log::debug("Finished cloning vm");
    return 1;
}

#tested
sub create_test_vm {
    my ($name) = @_;
    &Log::debug("Starting VCenter::create_test_vm");
    &num_check( 'test_1337', 'ResourcePool' );
    my $resource_pool = &Guest::entity_name_view( 'test_1337', 'ResourcePool' );
    &num_check( 'test_1337', 'Folder' );
    my $folder = &Guest::entity_name_view( 'test_1337', 'Folder' );
    &num_check( 'test_1337', 'DistributedVirtualSwitch' );
    my $host_view = Vim::find_entity_view(
        view_type  => 'HostSystem',
        properties => ['network'],
        filter     => { name => 'vmware-it1.balabit' }
    );
    my $network_list = Vim::get_views( mo_ref_array => $host_view->network );
    my @vm_devices;
    my $files = VirtualMachineFileInfo->new(
        logDirectory      => undef,
        snapshotDirectory => undef,
        suspendDirectory  => undef,
        vmPathName        => '[support] test_1337'
    );

    foreach (@$network_list) {
        if ( $_->name =~ /^test_1337_dvg/ ) {
            my $network          = $_;
            my $nic_backing_info = VirtualEthernetCardNetworkBackingInfo->new(
                deviceName    => 'test_1337_dvg',
                useAutoDetect => 1,
                network       => $network
            );
            my $vd_connect_info = VirtualDeviceConnectInfo->new(
                allowGuestControl => 1,
                connected         => 0,
                startConnected    => 1
            );
            my $nic = VirtualPCNet32->new(
                backing     => $nic_backing_info,
                key         => 0,
                addressType => 'generated',
                connectable => $vd_connect_info
            );
            my $nic_vm_dev_conf_spec = VirtualDeviceConfigSpec->new(
                device    => $nic,
                operation => VirtualDeviceConfigSpecOperation->new('add')
            );
            push( @vm_devices, $nic_vm_dev_conf_spec );
        }
    }
    my $config_spec = VirtualMachineConfigSpec->new(
        name         => $name,
        memoryMB     => '512',
        files        => $files,
        numCPUs      => 1,
        guestId      => 'winNetEnterpriseGuest',
        deviceChange => \@vm_devices
    );
    $folder->CreateVM( pool => $resource_pool, config => $config_spec );
    return 1;
}

sub create_test_entities {
    &VCenter::create_resource_pool( 'test_1337', 'Resources' );
    &VCenter::create_folder( 'test_1337', 'vm' );
    &VCenter::create_switch('test_1337');
    return 1;
}
### Helper subs to query information
#tested
sub num_check {
    my ( $name, $type ) = @_;
    &Log::debug(
        "Starting VCenter::num_check sub, name=>'$name', type=>'$type'");
    my $views = Vim::find_entity_views(
        view_type  => $type,
        properties => ['name'],
        filter     => { name => $name }
    );
    &Log::dumpobj( "views", $views );
    if ( scalar(@$views) ne 1 ) {
        Entity::NumException->throw(
            error  => 'Entity count not expected',
            entity => $name,
            count  => scalar(@$views)
        );
    }
    &Log::debug("Entity is single");
    return 1;
}

#tested
sub exists_entity {
    my ( $name, $type ) = @_;
    &Log::debug(
        "Starting VCenter::exists_entity sub, name=>'$name', type=>'$type'");
    my $view = Vim::find_entity_view(
        view_type  => $type,
        properties => ['name'],
        filter     => { name => $name }
    );
    &Log::dumpobj( "view", $view );
    if ( !defined($view) ) {
        &Log::debug("Entity does not exist");
        return 0;
    }
    return 1;
}

#tested
sub path2name {
    my ($path) = @_;
    &Log::debug("Starting VCenter::path2name sub, path=>'$path'");
    my $sc = &service_content;
    my $searchindex = Vim::get_view( mo_ref => $sc->searchIndex );
    my $moref = $searchindex->FindByInventoryPath( inventoryPath => $path );
    if ( !defined($moref) ) {
        Vcenter::Path->throw(
            error => "Could not retrieve moref from path",
            path  => $path
        );
    }
    my $view = &moref2view($moref);
    return $view->name;
}

#tested
sub path2moref {
    my ($path) = @_;
    &Log::debug("Starting VCenter::path2moref sub, path=>'$path'");
    my $sc = &service_content;
    my $searchindex = Vim::get_view( mo_ref => $sc->searchIndex );
    my $moref = $searchindex->FindByInventoryPath( inventoryPath => $path );
    if ( !defined($moref) ) {
        Vcenter::Path->throw(
            error => "Could not retrieve moref from path",
            path  => $path
        );
    }
    &Log::dumpobj( "moref", $moref );
    &Log::debug("Returning moref");
    return $moref;
}

#tested
sub moref2view {
    my ($moref) = @_;
    &Log::debug("Starting VCenter::moref2view sub");
    &Log::dumpobj( "moref", $moref );
    my $view = Vim::get_view( mo_ref => $moref );
    if ( !defined($view) ) {
        Entity::Status->throw( error => "Could not retrieve view from moref" );
    }
    &Log::dumpobj( "view", $view );
    &Log::debug("Returning view");
    return $view;
}

sub linked_clone_folder {
    my ($temp_name) = @_;
    &Log::debug(
        "Starting VCenter::linked_clone_folder sub, temp_name=>'$temp_name'");
    my $temp_fol;
    if ( &exists_entity( $temp_name, 'Folder' ) ) {
        &Log::info("Linked clone folder already exists");
        $temp_fol = &Guest::entity_name_view( $temp_name, 'Folder' );
    }
    else {
        &Log::info("Need to create the linked folder");
        my $temp_view = Vim::find_entity_view(
            view_type  => 'VirtualMachine',
            properties => ['parent'],
            filter     => { name => qr/$temp_name$/ }
        );
        my $parent_view = &moref2view( $temp_view->parent );
        $temp_fol = &create_folder( $temp_name, $parent_view->name );
    }
    return $temp_fol;
}

#tested
sub check_if_empty_entity {
    my ( $name, $type ) = @_;
    &Log::debug( "Starting VCenter::check_if_empty_entity sub, name=>'"
          . $name
          . "', type=>'"
          . $type
          . "'" );
    my $view;
    if ( $type eq 'DistributedVirtualSwitch' ) {
        $view = Vim::find_entity_view(
            view_type  => $type,
            properties => [ 'summary.portgroupName', 'name' ],
            filter     => { name => $name }
        );
    }
    elsif ( $type eq 'ResourcePool' ) {
        $view = Vim::find_entity_view(
            view_type  => $type,
            properties => [ 'name', 'vm', 'resourcePool' ],
            filter => { name => $name }
        );
    }
    elsif ( $type eq 'Folder' ) {
        $view = Vim::find_entity_view(
            view_type  => $type,
            properties => [ 'name', 'childEntity' ],
            filter     => { name => $name }
        );
    }
    if ( !defined($view) ) {
        Entity::NumException->throw(
            error  => "$type does not exist",
            entity => $name,
            count  => '0'
        );
    }
    if ( $type eq 'DistributedVirtualSwitch' ) {
        my $count = $view->get_property('summary.portgroupName');
        if ( @$count < 2 ) {
            &Log::debug("Switch is empty");
            return 1;
        }
    }
    elsif ( $type eq 'ResourcePool' ) {
        if ( !defined( $view->vm ) and !defined( $view->resourcePool ) ) {
            &Log::debug("Resorcepool pool is empty");
            return 1;
        }
    }
    elsif ( $type eq 'Folder' ) {
        if ( !defined( $view->childEntity ) ) {
            &Log::debug("Folder is empty");
            return 1;
        }
    }
    &Log::debug("Entity has child entities");
    return 0;
}

#tested
sub Task_Status {
    my ($taskRef) = @_;
    &Log::debug("Starting VCenter::Task_Status sub");
    my $task_view = Vim::get_view( mo_ref => $taskRef, type => 'Task' );
    if ( !defined($task_view) ) {
        TaskEr::NotDefined->throw(
            error => 'No task_view found for reference' );
    }
    my $continue = 1;
    my $progress = 0;
    while ($continue) {
        &Log::debug1("Looping through Task query");
        $task_view->ViewBase::update_view_data();
        if ( defined( $task_view->info->progress )
            and $progress ne $task_view->info->progress )
        {
            &Log::info( "Currently at " . $task_view->info->progress . "%" );
            $progress = $task_view->info->progress;
        }
        elsif ( $task_view->info->state->val eq 'success' ) {
            &Log::debug("Task was successful");
            $continue = 0;
        }
        elsif ( $task_view->info->state->val eq 'error' ) {
            TaskEr::Error->throw(
                error  => 'Error happened during task',
                detail => $task_view->info->error->fault,
                fault  => $task_view->info->error->localizedMessage
            );
        }
    }
    &Log::debug("Finishing VCenter::Task_status sub");
    return 1;
}

#tested
sub ticket_vms_name {
    my ($ticket) = @_;
    &Log::debug("Starting VCenter::ticket_vms_name sub, ticket=>'$ticket'");
    my $vms = Vim::find_entity_views(
        view_type  => 'VirtualMachine',
        properties => ['name'],
        filter     => { name => qr/^$ticket-/ }
    );
    my @return;
    for my $vm (@$vms) {
        push( @return, $vm->name );
    }
    return \@return;
}

#tested
sub name2path {
    my ($name) = @_;
    &Log::debug("Starting VCenter::name2path sub, name=>'$name'");
    my $vim  = &get_vim;
    my $view = &Guest::entity_name_view( $name, 'VirtualMachine' );
    my $path = Util::get_inventory_path( $view, $vim );
    &Log::debug("Returning path=>'$path'");
    return $path;
}

### Subs for creation/deletion
#tested
sub create_resource_pool {
    my ( $rp_name, $rp_parent ) = @_;
    &Log::debug( "Starting VCenter::create_resource_pool sub, rp_name=>'"
          . $rp_name
          . "', rp_parent=>'"
          . $rp_parent
          . "'" );
    my $type = 'ResourcePool';
    if ( &exists_entity( $rp_name, $type ) ) {
        &Log::debug("Resource pool already exists on VCenter");
        Entity::NumException->throw(
            error  => 'Resource pool already exists. Cannot create',
            entity => $rp_name,
            count  => '1'
        );
    }
    elsif ( !&exists_entity( $rp_parent, $type ) ) {
        &Log::debug("Resource pool parent doesn't exists on VCenter");
        Entity::NumException->throw(
            error  => 'Resource pool parent doesn\'t exist. Cannot create',
            entity => $rp_parent,
            count  => '0'
        );
    }
    my $rp_parent_view = Vim::find_entity_view(
        view_type  => $type,
        properties => ['name'],
        filter     => { name => $rp_parent }
    );
    ## Creation objects
    my $shareslevel = SharesLevel->new('normal');
    my $cpushares   = SharesInfo->new( shares => 4000, level => $shareslevel );
    my $memshares   = SharesInfo->new( shares => 32928, level => $shareslevel );
    my $cpuallocation = ResourceAllocationInfo->new(
        expandableReservation => 'true',
        limit                 => -1,
        reservation           => 0,
        shares                => $cpushares
    );
    my $memoryallocation = ResourceAllocationInfo->new(
        expandableReservation => 'true',
        limit                 => -1,
        reservation           => 0,
        shares                => $memshares
    );
    my $rp_spec = ResourceConfigSpec->new(
        cpuAllocation    => $cpuallocation,
        memoryAllocation => $memoryallocation
    );
    &Log::debug("Starting creation of resource pool in parent");
    &Log::dumpobj( "rp_spec", $rp_spec );
    my $rp_name_view =
      $rp_parent_view->CreateResourcePool( name => $rp_name, spec => $rp_spec );

    if ( $rp_name_view->type ne $type ) {
        Entity::NumException->throw(
            error  => 'Could not create resource pool',
            entity => $rp_name,
            count  => '0'
        );
    }
    &Log::debug("Resource pool creation was succesful");
    &Log::dumpobj( "rp_name_view", $rp_name_view );
    return $rp_name_view;
}

#tested
sub create_folder {
    my ( $fol_name, $fol_parent ) = @_;
    &Log::debug(
"Starting VCenter::create_folder sub, fol_name=>'$fol_name', fol_parent=>'$fol_parent'"
    );
    my $type = 'Folder';
    if ( &exists_entity( $fol_name, $type ) ) {
        &Log::debug("Folder already exists on VCenter");
        Entity::NumException->throw(
            error  => 'Folder already exists. Cannot create',
            entity => $fol_name,
            count  => '1'
        );
    }
    elsif ( !&exists_entity( $fol_parent, $type ) ) {
        &Log::debug("Folder parent doesn't exists on VCenter");
        Entity::NumException->throw(
            error  => 'Folder parent doesn\'t exist. Cannot create',
            entity => $fol_parent,
            count  => '0'
        );
    }
    my $fol_parent_view = &Guest::entity_name_view( $fol_parent, 'Folder' );
    &Log::dumpobj( 'fol_parent_view', $fol_parent_view );
    &Log::debug("Starting creation of folder in parent");
    my $fol_name_view = $fol_parent_view->CreateFolder( name => $fol_name );
    if ( $fol_name_view->type ne $type ) {
        Entity::NumException->throw(
            error  => 'Could not create folder',
            entity => $fol_name,
            count  => '0'
        );
    }
    &Log::dumpobj( 'fol_name_view', $fol_name_view );
    &Log::debug("Folder creation was succesful");
    return $fol_name_view;
}

#tested
sub create_switch {
    my ($name) = @_;
    &Log::debug("Starting VCenter::create_switch sub, name=>'$name'");
    &num_check( 'network', 'Folder' );
    if ( &exists_entity( $name, 'DistributedVirtualSwitch' ) ) {
        Entity::NumException->throw(
            error  => 'Cannot create switch, already exists',
            entity => $name,
            count  => '1'
        );
    }
    my $network_folder = &Guest::entity_name_view( 'network', 'Folder' );
    &num_check( 'vmware-it1.balabit', 'HostSystem' );
    my $host_view =
      &Guest::entity_name_view( 'vmware-it1.balabit', 'HostSystem' );
    my $hostspec = DistributedVirtualSwitchHostMemberConfigSpec->new(
        operation           => 'add',
        maxProxySwitchPorts => 99,
        host                => $host_view
    );
    &Log::dumpobj( "hostspec", $hostspec );
    my $dvsconfigspec = DVSConfigSpec->new(
        name        => $name,
        maxPorts    => 300,
        description => "DVS for ticket $name",
        host        => [$hostspec]
    );
    &Log::dumpobj( "dvsconfigspec", $dvsconfigspec );
    my $spec = DVSCreateSpec->new( configSpec => $dvsconfigspec );
    &Log::dumpobj( "spec", $spec );
    my $task = $network_folder->CreateDVS_Task( spec => $spec );
    &Log::dumpobj( "task", $task );
    &Task_Status($task);
    &Log::debug("Finished creating switch");
    return 1;
}

#tested
sub create_dvportgroup {
    my ( $name, $switch ) = @_;
    &Log::debug(
"Starting VCenter::create_dvportgroup sub, name=>'$name', switch=>'$switch'"
    );
    if ( &exists_entity( $name, 'DistributedVirtualPortgroup' ) ) {
        Entity::NumException->throw(
            error  => 'Cannot create entity, already exists',
            entity => $name,
            count  => '1'
        );
    }
    &num_check( $switch, 'DistributedVirtualSwitch' );
    my $switch_view =
      &Guest::entity_name_view( $switch, 'DistributedVirtualSwitch' );
    &Log::dumpobj( "switch_view", $switch_view );
    my $spec = DVPortgroupConfigSpec->new(
        name        => $name,
        type        => 'earlyBinding',
        numPorts    => 20,
        description => "Port group"
    );
    &Log::dumpobj( "spec", $spec );
    my $task = $switch_view->AddDVPortgroup_Task( spec => $spec );
    &Log::dumpobj( "task", $task );
    &Task_Status($task);
    &Log::debug("Finished creating dv port group");
    return 1;
}

#tested
sub destroy_entity {
    my ( $name, $type ) = @_;
    &Log::debug(
        "Starting VCenter::destroy_entity sub, name=>'$name', type=>'$type'");
    &num_check( $name, $type );
    my $view = &Guest::entity_name_view( $name, $type );
    my $task = $view->Destroy_Task;
    &Task_Status($task);
    $view = Vim::find_entity_view(
        view_type  => $type,
        properties => ['name'],
        filter     => { name => $name }
    );
    if ( defined($view) ) {
        Entity::NumException->throw(
            error  => 'Could not delete entity',
            entity => $name,
            count  => '1'
        );
    }
    &Log::debug("Entity delete succesful");
    return 1;
}

### Subs for connection and buildup to VCenter
#tested
sub SDK_options {
    my $opts = shift;
    &Log::debug("Starting VCenter::SDK_options");
    Opts::add_options(%$opts);
    Opts::parse();
    Opts::validate();
    &Log::debug("Options validated succesfully");
    return 1;
}

#tested
sub connect_vcenter {
    &Log::debug("Starting VCenter::connect_vcenter sub");
    eval {
        Util::connect(
            Opts::get_option('url'),
            Opts::get_option('username'),
            Opts::get_option('password')
        );
    };
    if ($@) {
        Connection::Connect->throw(
            error => 'Failed to connect to VCenter',
            type  => 'SDK',
            dest  => 'VCenter'
        );
    }
    &Log::debug("Connected succesfully to VCenter");
    return 1;
}

#tested
sub disconnect_vcenter {
    &Log::debug("Starting VCenter::disconnect_vcenter sub");
    Util::disconnect();
    return 1;
}

#tested
sub service_content {
    &Log::debug("Retrieving VCenter::Service Content object");
    my $sc = Vim::get_service_content();
    if ( !defined($sc) ) {
        Vcenter::ServiceContent->throw(
            error => 'Could not retrieve service content' );
    }
    &Log::dumpobj( "service_content", $sc );
    &Log::debug("Returning service content object");
    return $sc;
}

#tested
sub get_vim {
    &Log::debug("Starting VCenter::Vim object retrieve");
    my $vim = Vim::get_vim();
    if ( !defined($vim) ) {
        VCenter::ServiceContent->throw(
            error => 'Could not retrieve Vim object' );
    }
    &Log::dumpobj( "vim", $vim );
    &Log::debug("Returning vim object");
    return $vim;
}

1
__END__
