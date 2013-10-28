package VCenter;

use strict;
use warnings;

=pod

=head1 VCenter.pm

Subroutines for BB/VCenter.pm

=cut

BEGIN {
    use Exporter;
    our @ISA    = qw( Exporter );
    our @EXPORT = qw( );
}

=pod

=head2 num_check

=head3 PURPOSE

Checks if the entity only exists once

=head3 PARAMETERS

=over

=item name

Name of the entity

=item type

Type of entity

=back

=head3 RETURNS

True on success

=head3 DESCRIPTION

=head3 THROWS

Entity::NumException if the result is not 1

=head3 COMMENTS

=head3 TEST COVERAGE

=cut

sub num_check {
    my ( $name, $type ) = @_;
    &Log::debug("Starting VCenter::num_check sub");
    &Log::debug1("Opts are: name=>'$name', type=>'$type'");
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
    &Log::debug("Finishing VCenter::num_check sub");
    return 1;
}

=pod

=head2 exists_entity

=head3 PURPOSE

Checks if entity exists or not with true or false

=head3 PARAMETERS

=over

=item name

Name of the entity

=item type

Type of entity

=back

=head3 RETURNS

True if entity can be found
False if entity cannot be found

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

=head3 TEST COVERAGE

=cut

sub exists_entity {
    my ( $name, $type ) = @_;
    &Log::debug("Starting VCenter::exists_entity sub");
    &Log::debug("Opts are: name=>'$name', type=>'$type'");
    my $view = Vim::find_entity_view(
        view_type  => $type,
        properties => ['name'],
        filter     => { name => $name }
    );
    &Log::dumpobj( "view", $view );
    my $ret = 0;
    if ( defined($view) ) {
        &Log::debug("Entity exists, changing return to true");
        $ret = 1;
    }
    &Log::debug("Finishing VCenter::exists_entity sub");
    return $ret;
}

=pod

=head2 path2name

=head3 PURPOSE

Converts a VCenter inventory path to Name

=head3 PARAMETERS

=over

=item path

VCenter inventory path

=back

=head3 RETURNS

=head3 DESCRIPTION

=head3 THROWS

Vcenter:Path if no entity is found with the requested path

=head3 COMMENTS

=head3 TEST COVERAGE

=cut

sub path2name {
    my ($path) = @_;
    &Log::debug("Starting VCenter::path2name sub");
    &Log::debug1("Opts are: path=>'$path'");
    my $searchindex = &VCenter::get_manager("searchIndex");
    my $moref = $searchindex->FindByInventoryPath( inventoryPath => $path );
    if ( !defined($moref) ) {
        Vcenter::Path->throw(
            error => "Could not retrieve moref from path",
            path  => $path
        );
    }
    my $view = &VCenter::moref2view($moref);
    &Log::debug("Finishing VCenter::path2name sub");
    &Log::debug( "Returning=>'" . $view->name . "'" );
    return $view->name;
}

=pod

=head2 path2moref

=head3 PURPOSE

Converts a VCenter inventory path to a Managed object reference

=head3 PARAMETERS

=over

=item path

VCenter inventory path

=back

=head3 RETURNS

=head3 DESCRIPTION

=head3 THROWS

Vcenter:Path if no entity is found with the requested path

=head3 COMMENTS

=head3 TEST COVERAGE

=cut

sub path2moref {
    my ($path) = @_;
    &Log::debug("Starting VCenter::path2moref sub");
    &Log::debug1("Opts are: path=>'$path'");
    my $searchindex = &VCenter::get_manager("searchIndex");
    my $moref = $searchindex->FindByInventoryPath( inventoryPath => $path );
    if ( !defined($moref) ) {
        Vcenter::Path->throw(
            error => "Could not retrieve moref from path",
            path  => $path
        );
    }
    &Log::dumpobj( "moref", $moref );
    &Log::debug("Finishing VCenter::path2moref sub");
    return $moref;
}

=pod

=head2 moref2view

=head3 PURPOSE

Converts a moref to a view

=head3 PARAMETERS

=over

=item moref

A managed object reference

=back

=head3 RETURNS

A Managed object to the reference

=head3 DESCRIPTION

=head3 THROWS

Entity::Status if the get_view returned with undef

=head3 COMMENTS

=head3 TEST COVERAGE

=cut

sub moref2view {
    my ($moref) = @_;
    &Log::debug("Starting VCenter::moref2view sub");
    &Log::dumpobj( "moref", $moref );
    my $view = Vim::get_view( mo_ref => $moref );
    if ( !defined($view) ) {
        Entity::Status->throw( error => "Could not retrieve view from moref" );
    }
    &Log::dumpobj( "view", $view );
    &Log::debug("Finishing VCenter::moref2view sub");
    return $view;
}

=pod

=head2 linked_clone_folder

=head3 PURPOSE

Creates a folder for the template where the linked clones can be stored

=head3 PARAMETERS

=over

=item temp_name

The template name

=back

=head3 RETURNS

A managed object to the folder

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

=head3 TEST COVERAGE

=cut

sub linked_clone_folder {
    my ($temp_name) = @_;
    &Log::debug("Starting VCenter::linked_clone_folder sub");
    &Log::debug1("Opts are: temp_name=>'$temp_name'");
    my $temp_fol;
    if ( &VCenter::exists_entity( $temp_name, 'Folder' ) ) {
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
        my $parent_view = &VCenter::moref2view( $temp_view->parent );
        $temp_fol = &VCenter::create_folder( $temp_name, $parent_view->name );
    }
    &Log::dumpobj( "temp_fol", $temp_fol );
    &Log::debug("Finishing VCenter::moref2view sub");
    return $temp_fol;
}

=pod

=head2 check_if_empty_entity

=head3 PURPOSE

Checks if the entity is empty or has children

=head3 PARAMETERS

=over

=item name

Name of entity

=item type

Type of entity

=back

=head3 RETURNS

True if has children
False if entity is empty

=head3 DESCRIPTION

=head3 THROWS

Entity::NumException if no entity found or unknown type is requested

=head3 COMMENTS

=head3 TEST COVERAGE

=cut

sub check_if_empty_entity {
    my ( $name, $type ) = @_;
    &Log::debug("Starting VCenter::check_if_empty_entity sub");
    &Log::debug1("Opts are: name=>'$name', type=>'$type'");
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
    else {
        Entity::NumException->throw(
            error  => "$type is not handled",
            entity => $name,
            count  => '0'
        );
    }
    if ( !defined($view) ) {
        Entity::NumException->throw(
            error  => "$type does not exist",
            entity => $name,
            count  => '0'
        );
    }
    my $ret = 0;
    if ( $type eq 'DistributedVirtualSwitch' ) {
        my $count = $view->get_property('summary.portgroupName');
        if ( @$count < 2 ) {
            &Log::info("Switch is empty");
            $ret = 1;
        }
        else {
            &Log::info("Switch has childre");
        }
    }
    elsif ( $type eq 'ResourcePool' ) {
        if ( !defined( $view->vm ) and !defined( $view->resourcePool ) ) {
            &Log::info("Resorcepool is empty");
            $ret = 1;
        }
        else {
            &Log::info("Resourcepool has children");
        }
    }
    elsif ( $type eq 'Folder' ) {
        if ( !defined( $view->childEntity ) ) {
            &Log::info("Folder is empty");
            $ret = 1;
        }
        else {
            &Log::info("Folder has children");
        }
    }
    &Log::debug("Finishing VCenter::check_if_empty_entity sub");
    &Log::debug("Return is $ret");
    return $ret;
}

=pod

=head2 Task_Status

=head3 PURPOSE

Checks task status and prints progress

=head3 PARAMETERS

=over

=item taskRef

A Managed object reference to a task

=back

=head3 RETURNS

True on success

=head3 DESCRIPTION

=head3 THROWS

TaskEr::Error if there was an error during the task

=head3 COMMENTS

=head3 TEST COVERAGE

=cut

sub Task_Status {
    my ($taskRef) = @_;
    &Log::debug("Starting VCenter::Task_Status sub");
    &Log::dumpobj( "taskRef", $taskRef );
    my $task_view = &VCenter::moref2view($taskRef);
    my $progress  = 0;
    while (1) {
        &Log::debug1("Looping through Task query");

        #$task_view->ViewBase::update_view_data();
        $task_view->update_view_data;
        if ( defined( $task_view->info->progress )
            and $progress ne $task_view->info->progress )
        {
            &Log::info( "Currently at " . $task_view->info->progress . "%" );
            $progress = $task_view->info->progress;
        }
        elsif ( $task_view->info->state->val eq 'success' ) {
            &Log::debug("Task was successful");
            last;
        }
        elsif ( $task_view->info->state->val eq 'error' ) {
            TaskEr::Error->throw(
                error  => 'Error happened during task',
                detail => $task_view->info->error->fault,
                fault  => $task_view->info->error->localizedMessage
            );
        }
        else {
            sleep 1;
        }
    }
    &Log::debug("Finishing VCenter::Task_status sub");
    return 1;
}

=pod

=head2 ticket_vms_name

=head3 PURPOSE

Returns array ref with vmnames attached to a ticket

=head3 PARAMETERS

=over

=item ticket

Ticket number to return names of

=back

=head3 RETURNS

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

=head3 TEST COVERAGE

=cut

sub ticket_vms_name {
    my ($ticket) = @_;
    &Log::debug("Starting VCenter::ticket_vms_name sub");
    &Log::debug1("Opts are: ticket=>'$ticket'");
    my $vms = Vim::find_entity_views(
        view_type  => 'VirtualMachine',
        properties => ['name'],
        filter     => { name => qr/^$ticket-/ }
    );
    &Log::dumpobj( "vms", $vms );
    my @return;
    for my $vm (@$vms) {
        &Log::debug( "Pushing to return array '" . $vm->name . "'" );
        push( @return, $vm->name );
    }
    &Log::dumpobj( "return", \@return );
    &Log::debug("Finishing VCenter::ticket_vms_name sub");
    return \@return;
}

=pod

=head2 name2path

=head3 PURPOSE

Converts an entity name to VCenter inventory path

=head3 PARAMETERS

=over

=item name

Name of entity whoes name should be converted

=back

=head3 RETURNS

Inventory path of entity

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

=head3 TEST COVERAGE

=cut

sub name2path {
    my ($name) = @_;
    &Log::debug("Starting VCenter::name2path sub");
    &Log::debug1("Opts are: name=>'$name'");
    my $vim  = &VCenter::get_vim;
    my $view = &Guest::entity_name_view( $name, 'VirtualMachine' );
    my $path = Util::get_inventory_path( $view, $vim );
    &Log::debug("Finishing VCenter::name2path sub");
    &Log::debug("Returning=>'$path'");
    return $path;
}

=pod

=head2 create_resource_pool

=head3 PURPOSE

Creating a resourcepool in requested parent resourcepool

=head3 PARAMETERS

=over

=item rp_name

Name of requested resourcepool

=item rp_parent

Name of requested resourcepool parent

=back

=head3 RETURNS

Managed object of new resourcepool

=head3 DESCRIPTION

=head3 THROWS

Entity::NumException if parent doesn't exist or resourcepool already exists

=head3 COMMENTS

=head3 TEST COVERAGE

=cut

sub create_resource_pool {
    my ( $rp_name, $rp_parent ) = @_;
    &Log::debug("Starting VCenter::create_resource_pool sub");
    &Log::debug("Opts are: rp_name=>'$rp_name', rp_parent=>'$rp_parent'");
    my $type = 'ResourcePool';
    if ( &VCenter::exists_entity( $rp_name, $type ) ) {
        Entity::NumException->throw(
            error  => 'Resource pool already exists. Cannot create',
            entity => $rp_name,
            count  => '1'
        );
    }
    elsif ( !&VCenter::exists_entity( $rp_parent, $type ) ) {
        Entity::NumException->throw(
            error  => 'Resource pool parent doesn\'t exist. Cannot create',
            entity => $rp_parent,
            count  => '0'
        );
    }
    my $rp_parent_view = &Guest::entity_name_view( $rp_parent, $type );
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
    &Log::debug("Finishing VCenter::create_resource_pool sub");
    &Log::dumpobj( "rp_name_view", $rp_name_view );
    return $rp_name_view;
}

=pod

=head2 create_folder

=head3 PURPOSE

Create an inventory folder with requested name

=head3 PARAMETERS

=over

=item fol_name

Name of requested folder

=item fol_parent

Parent of requested folder

=back

=head3 RETURNS

Managed object of created folder

=head3 DESCRIPTION

=head3 THROWS

Entity::NumException if requested folder exists or parent doesn't exist

=head3 COMMENTS

=head3 TEST COVERAGE

=cut

sub create_folder {
    my ( $fol_name, $fol_parent ) = @_;
    &Log::debug("Starting VCenter::create_folder sub");
    &Log::debug1("Opts are: fol_name=>'$fol_name', fol_parent=>'$fol_parent'");
    my $type = 'Folder';
    if ( &VCenter::exists_entity( $fol_name, $type ) ) {
        Entity::NumException->throw(
            error  => 'Folder already exists. Cannot create',
            entity => $fol_name,
            count  => '1'
        );
    }
    elsif ( !&VCenter::exists_entity( $fol_parent, $type ) ) {
        Entity::NumException->throw(
            error  => 'Folder parent doesn\'t exist. Cannot create',
            entity => $fol_parent,
            count  => '0'
        );
    }
    my $fol_parent_view = &Guest::entity_name_view( $fol_parent, $type );
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
    &Log::debug("Finishing VCenter::create_folder sub");
    return $fol_name_view;
}

=pod

=head2 create_switch

=head3 PURPOSE

Creates aerquested Distributed Virtual Switch

=head3 PARAMETERS

=over

=item name

Name of requested switch name

=back

=head3 RETURNS

True on success

=head3 DESCRIPTION

=head3 THROWS

Entity::NumException if switch already exists

=head3 COMMENTS

=head3 TEST COVERAGE

=cut

sub create_switch {
    my ($name) = @_;
    &Log::debug("Starting VCenter::create_switch sub");
    &Log::debug1("Opts are: name=>'$name'");
    &VCenter::num_check( 'network', 'Folder' );
    if ( &VCenter::exists_entity( $name, 'DistributedVirtualSwitch' ) ) {
        Entity::NumException->throw(
            error  => 'Cannot create switch, already exists',
            entity => $name,
            count  => '1'
        );
    }
    my $network_folder = &Guest::entity_name_view( 'network', 'Folder' );
    &VCenter::num_check( 'vmware-it1.balabit', 'HostSystem' );
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
    my $spec = DVSCreateSpec->new( configSpec => $dvsconfigspec );
    &Log::dumpobj( "spec", $spec );
    my $task = $network_folder->CreateDVS_Task( spec => $spec );
    &VCenter::Task_Status($task);
    &Log::debug("Finishing VCenter::create_switch sub");
    return 1;
}

=pod

=head2 create_dvportgroup

=head3 PURPOSE

Create a requested Distributed Virtual Portgroup

=head3 PARAMETERS

=over

=item name

Requested name for distributed virtual Portgroup

=item switch

Parent switch for portgroup

=back

=head3 RETURNS

True on success

=head3 DESCRIPTION

=head3 THROWS

Entity::NumException if entity already exists

=head3 COMMENTS

=head3 TEST COVERAGE

=cut

sub create_dvportgroup {
    my ( $name, $switch ) = @_;
    &Log::debug(
"Starting VCenter::create_dvportgroup sub, name=>'$name', switch=>'$switch'"
    );
    if ( &VCenter::exists_entity( $name, 'DistributedVirtualPortgroup' ) ) {
        Entity::NumException->throw(
            error  => 'Cannot create entity, already exists',
            entity => $name,
            count  => '1'
        );
    }
    &VCenter::num_check( $switch, 'DistributedVirtualSwitch' );
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
    &VCenter::Task_Status($task);
    &Log::debug("Finished creating dv port group");
    return 1;
}

=pod

=head2 destroy_entity

=head3 PURPOSE

Destroy a requested entity type

=head3 PARAMETERS

=over

=item name

Name of entity to destroy

=item type

Type of entity

=back

=head3 RETURNS

True on success

=head3 DESCRIPTION

=head3 THROWS

Entity::NumException if delete was not successful

=head3 COMMENTS

=head3 TEST COVERAGE

=cut

sub destroy_entity {
    my ( $name, $type ) = @_;
    &Log::debug("Starting VCenter::destroy_entity sub");
    &Log::debug1("Opts are: name=>'$name', type=>'$type'");
    my $view = &Guest::entity_name_view( $name, $type );
    my $task = $view->Destroy_Task;
    &VCenter::Task_Status($task);
    &Log::info("Finished destroying entity, checking if destroy was succesful");
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
    else {
        &Log::debug("Destroy was successful");
    }
    &Log::debug("Finishing VCenter::destroy_entity sub");
    return 1;
}

=pod

=head2 vm_last_snapshot_view

=head3 PURPOSE

Returns last snapshot for a vm

=head3 PARAMETERS

=over

=item vmname

Virtual Machine name

=back

=head3 RETURNS

Managed object of requested snapshot

=head3 DESCRIPTION

Sub only handles one tier at level 0!
Reason: If a sceneraio requires that the initial disk have multiple snapshot for different uses, than
than is a fubar and should be handled with multiple machines. There can be later recursions to different points
but it should not diverge deeply and create multi depth hiearchy for snapshots. To handle these are not
trivial and not best practices. A snapshot should be used for short times and deleted afterwards

=head3 THROWS

Entity::Snapshot if virtual machine has no snapshots defined

=head3 COMMENTS

=head3 TEST COVERAGE

=cut

sub vm_last_snapshot_view {
    my ($vmname) = @_;
    &Log::debug("Starting VCenter::vm_last_snapshot_view sub");
    &Log::debug1("Opts are: vmname=>'$vmname'");
    my $view =
      &Guest::entity_property_view( $vmname, 'VirtualMachine', 'snapshot' );
    my $snapshot_view;
    if (   defined( $view->snapshot )
        && defined( $view->snapshot->rootSnapshotList ) )
    {
        $snapshot_view = $view->snapshot->rootSnapshotList;
    }
    else {
        Entity::Snapshot->throw(
            error    => 'VM has no snapshots defined',
            entity   => $vmname,
            snapshot => 'none'
        );
    }
    &Log::dumpobj( "snapshot_view", $snapshot_view );
    if ( defined( $snapshot_view->[0]->{'childSnapshotList'} ) ) {
        &Log::debug("Recursion for last snapshot");
        $snapshot_view =
          &Guest::find_last_snapshot(
            $snapshot_view->[0]->{'childSnapshotList'} );
        &Log::debug("End of recursion");
    }
    &Log::dumpobj( "snapshot_view", $snapshot_view );
    my $snapshot = &VCenter::moref2view( $snapshot_view->[0]->{'snapshot'} );
    &Log::dumpobj( "snapshot", $snapshot );
    &Log::debug("Finishing VCenter::vm_last_snapshot_view sub");
    return $snapshot;
}

=pod

=head2 find_vms_with_disk

=head3 PURPOSE

Returns array ref with all machines linked to a vmdk disk

=head3 PARAMETERS

=over

=item disk

A datastore path to a vmdk file

=back

=head3 RETURNS

Array ref with all virtual machines linked to the disk

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

=head3 TEST COVERAGE

=cut

sub find_vms_with_disk {
    my ($disk) = @_;
    &Log::debug("Starting VCenter::find_vms_with_disk sub");
    &Log::debug1("Opts are: disk=>'$disk'");
    my @vms           = ();
    my $machine_views = Vim::find_entity_views(
        view_type  => 'VirtualMachine',
        properties => [ 'layout.disk', 'name' ]
    );
    foreach (@$machine_views) {
        my $machine_view = $_;
        &Log::debug( "Iterating through: '" . $machine_view->name . "'" );
        &Log::dumpobj( "machine_view", $machine_view );
        my $disks = $machine_view->get_property('layout.disk');
        foreach my $vdisk (@$disks) {
            &Log::debug("Checking disk");
            &Log::dumpobj( "vdisk", $vdisk );
            foreach my $diskfile ( @{ $vdisk->{'diskFile'} } ) {
                &Log::debug("Checking diskfile path: diskFile=>'$diskfile'");
                if ( $diskfile eq $disk ) {
                    &Log::debug1("Found vm with disk. Pushing to array");
                    push( @vms, $machine_view->get_property('name') );
                }
                else {
                    &Log::debug1("Disk is not requested disk");
                }
            }
        }
    }
    &Log::debug("Finishing VCenter::find_vms_with_disk sub");
    &Log::dumpobj( "vms", \@vms );
    return \@vms;
}

=pod

=head2 datastore_file_exists

=head3 PURPOSE

Checks if datastore file exists

=head3 PARAMETERS

=over

=item filename

Datastore path to file

=back

=head3 RETURNS

True if file exists
False if file does not exist

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

=head3 TEST COVERAGE

=cut

sub datastore_file_exists {
    my ($filename) = @_;
    &Log::debug("Starting VCenter::datastore_file_exists sub");
    &Log::debug("Opts are, filename=>'$filename'");
    my ( $datas, $folder, $image ) = @{ &Misc::filename_splitter($filename) };
    my $datastore =
      &Guest::entity_property_view( $datas, 'Datastore', 'browser' );
    my $browser = &VCenter::moref2view( $datastore->browser );
    my $files   = FileQueryFlags->new(
        fileSize     => 0,
        fileType     => 1,
        modification => 0,
        fileOwner    => 0
    );
    my $searchspec = HostDatastoreBrowserSearchSpec->new(
        details      => $files,
        matchPattern => [$image]
    );
    my $return = $browser->SearchDatastoreSubFolders(
        datastorePath => "[$datas] $folder",
        searchSpec    => $searchspec
    );
    my $ret = 0;

    if ( defined( $return->[0]->file ) ) {
        &Log::debug("Datastore file exists");
        $ret = 1;
    }
    else {
        &Log::debug("Datastore file doesn't exist");
    }
    &Log::debug("Finishing VCenter::datastore_file_exists sub");
    return $ret;
}

=pod

=head2 SDK_options

=head3 PURPOSE

For parsing SDK options and feeding the

=head3 PARAMETERS

=over

=item opts

A hash ref to the options that should be added

=back

=head3 RETURNS

True on success

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

=head3 TEST COVERAGE

=cut

sub SDK_options {
    my $opts = shift;
    &Log::debug("Starting VCenter::SDK_options sub");
    Opts::add_options(%$opts);
    Opts::parse();
    Opts::validate();
    &Log::debug("Finishing VCenter::SDK_options sub");
    return 1;
}

=pod

=head2 connect_vcenter

=head3 PURPOSE

Connecting to a VCenter

=head3 PARAMETERS

=over

=back

=head3 RETURNS

True on success

=head3 DESCRIPTION

=head3 THROWS

Connection::Connect if connection to VCenter fails

=head3 COMMENTS

=head3 TEST COVERAGE

=cut

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
    &Log::debug("Finishing VCenter:;connect_vcenter sub");
    return 1;
}

=pod

=head2 disconnect_vcenter

=head3 PURPOSE

Disconnects from VCenter

=head3 PARAMETERS

=over

=back

=head3 RETURNS

True on success

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

=head3 TEST COVERAGE

=cut

sub disconnect_vcenter {
    &Log::debug("Starting VCenter::disconnect_vcenter sub");
    Util::disconnect();
    &Log::debug("Finishing VCenter::disconnect_vcenter sub");
    return 1;
}

=pod

=head2 service_content

=head3 PURPOSE

Retrieves service content

=head3 PARAMETERS

=over

=back

=head3 RETURNS

Managed Object for a service content

=head3 DESCRIPTION

=head3 THROWS

Vcenter::ServiceContent if service content could not be retrieved

=head3 COMMENTS

=head3 TEST COVERAGE

Tested if correct object is returned

=cut

sub service_content {
    &Log::debug("Starting VCenter::service_content sub");
    my $sc = Vim::get_service_content();
    if ( !defined($sc) ) {
        Vcenter::ServiceContent->throw(
            error => 'Could not retrieve service content' );
    }
    &Log::dumpobj( "service_content", $sc );
    &Log::debug("Finishing VCenter::service_content sub");
    return $sc;
}

=pod

=head2 move_into_folder

=head3 PURPOSE

Moves a Virtual Machine into a folder

=head3 PARAMETERS

=over

=item vmname

Virtual Machine name

=item folder

The requested folder

=back

=head3 RETURNS

True on success

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

=head3 TEST COVERAGE

=cut

sub move_into_folder {
    my ( $vmname, $folder ) = @_;
    &Log::debug("Starting VCenter::move_into_folder sub");
    &Log::debug("Opts are, vmname=>'$vmname', folder=>'$folder'");
    my $view        = &Guest::entity_name_view( $vmname, 'VirtualMachine' );
    my $folder_view = &Guest::entity_name_view( $folder, 'Folder' );
    my $task = $folder_view->MoveIntoFolder_Task( list => [$view] );
    &VCenter::Task_Status($task);
    &Log::debug("Finishing VCenter::move_into_folder sub");
    return 1;
}

=pod

=head2 get_vim

=head3 PURPOSE

Retrieves a vim object

=head3 PARAMETERS

=over

=back

=head3 RETURNS

Vim object

=head3 DESCRIPTION

=head3 THROWS

Vcenter::ServiceContent if vim objcect could not be retrieved

=head3 COMMENTS

=head3 TEST COVERAGE

Tested if vim object is returned

=cut

sub get_vim {
    &Log::debug("Starting VCenter::get_vim sub");
    my $vim = Vim::get_vim();
    if ( !defined($vim) ) {
        Vcenter::ServiceContent->throw(
            error => 'Could not retrieve Vim object' );
    }
    &Log::dumpobj( "vim", $vim );
    &Log::debug("Finishing VCenter::get_view sub");
    return $vim;
}

=pod

=head2 get_manager

=head3 PURPOSE

Retrieve SErvice content manager

=head3 PARAMETERS

=over

=item type

Type of manager to retrieve
Possible values: accountManager, authManager, authorizationManager, clusterProfileManager, complianceManager, customFieldsManager, customizationSpecManager, diagnosticManager, dvSwitchManager, eventManager,
extensionManager, fileManager, hostProfileManager, ipPoolManager, licenseManager, localizationManager, ovfManager, perfManager, propertyCollector, rootFolder, scheduledTaskManager, searchIndex, sessionManager,
setting, snmpSystem, storageResourceManager, taskManager, userDirectory, viewManager, virtualDiskManager, virtualizationManager, vmCompatibilityChecker, vmProvisioningChecker

Undocumented : guestOperationsManager

=back

=head3 RETURNS

The Service content object requested

=head3 DESCRIPTION

=head3 THROWS

Vcenter::ServiceContent if no object is found with requested name

=head3 COMMENTS

=head3 TEST COVERAGE

=cut

sub get_manager {
    my ($type) = @_;
    &Log::debug("Starting VCenter::get_manager sub");
    &Log::debug1("Opts are: type=>'$type'");
    my $manager = &VCenter::moref2view( &VCenter::service_content->{$type} );
    &Log::dumpobj( $type, $manager );
    if ( !defined($manager) ) {
        Vcenter::ServiceContent->throw(
            error => "Could not retrieve $type Manager" );
    }
    &Log::debug("Finishing VCenter::get_manager sub");
    &Log::dumpobj( "$type manager", $manager );
    return $manager;
}

=pod

=head1 resourcepool_info

=head2 PURPOSE

Returns resourcepool information for printing or handling

=head2 PARAMETERS

=over

=item name

Name of resourcepool to return

=back

=head2 RETURNS

Array ref with resourcepool information

=head2 DESCRIPTION

Return information in array ref for routine like Output::add_row. Max is used to display the limits of a resourcepool

=head2 THROWS

=head2 COMMENTS

=head2 TEST COVERAGE

=cut

sub resourcepool_info {
    my ($name) = @_;
    &Log::debug("Starting VCenter::resourcepool_info sub");
    &Log::debug("Opts are: name=>'$name'");
    my @info;
    my $view = &Guest::entity_full_view( $name, 'ResourcePool' );
    push( @info, $name );
    if ( $view->{vm} ) {
        &Log::debug("Resourcepool has child Virtual Machines");
        push( @info, scalar( @{ $view->{vm} } ) );
    }
    else {
        &Log::debug("Resourcepool has no child Virtual Machines");
        push( @info, 0 );
    }
    if ( $view->{resourcePool} ) {
        &Log::debug("Resourcepool has child resourcepools");
        push( @info, scalar( @{ $view->{resourcePool} } ) );
    }
    else {
        &Log::debug("Resourcepool has no child resourcepools");
        push( @info, 0 );
    }
    push( @info, $view->{runtime}->{overallStatus}->{val} );
    my $memoryMB = int( $view->{runtime}->{memory}->{overallUsage} / 1048576 );
    push( @info, "${memoryMB}MB" );
    push( @info, "$view->{runtime}->{cpu}->{overallUsage}Mhz" );
    $memoryMB = int( $view->{runtime}->{memory}->{maxUsage} / 1048576 );
    push( @info, "${memoryMB}MB" );
    push( @info, "$view->{runtime}->{cpu}->{maxUsage}Mhz" );
    &Log::debug("Finishing VCenter::resourcepool_info sub");
    return \@info;
}

=pod

=head1 folder_info

=head2 PURPOSE

Gathers folder information

=head2 PARAMETERS

=over

=back

=head2 RETURNS

=head2 DESCRIPTION

=head2 THROWS

=head2 COMMENTS

=head2 SEE ALSO

=cut

sub folder_info {
    my ($name) = @_;
    &Log::debug("Starting VCenter::folder_info sub");
    &Log::debug1("Opts are: name=>'$name'");
    my %entities = ( VirtualMachine => [], Folder => [] );
    my $view = &Guest::entity_property_view( $name, 'Folder', 'childEntity' );
    for my $entity ( @{ $view->{childEntity} } ) {
        if ( defined( $entities{ $entity->{type} } ) ) {
            my $view = &VCenter::moref2view($entity);
            push( @{ $entities{ $entity->{type} } }, $view->{name} );
        }
        else {
            &Log::debug("Unhandled entity in Inventory Folder");
        }
    }
    &Log::dumpobj( "entities", \%entities );
    &Log::debug("Finishing VCenter::folder_info sub");
    return \%entities;
}

=pod

=head1 clonevm

=head2 PURPOSE

Clone a virtual machine with requested parameters

=head2 PARAMETERS

=over

=item template

Name of template

=item vmname

Name of requested virtual machine

=item folder

Name of parent folder

=item clone_spec

The VirtualMachineCloneSpec object

=back

=head2 RETURNS

True on success

=head2 DESCRIPTION

=head2 THROWS

=head2 COMMENTS

=head2 TEST COVERAGE

=cut

sub clonevm {
    my ( $template, $vmname, $folder, $clone_spec ) = @_;
    &Log::debug("Starting VCenter::clonevm sub");
    &Log::debug1(
        "Opts are: template=>'$template', vmname=>'$vmname', folder=>'$folder'"
    );
    &Log::dumpobj( "clone_spec", $clone_spec );
    my $template_view = &Guest::entity_name_view( $template, 'VirtualMachine' );
    my $folder_view   = &Guest::entity_name_view( $folder,   'Folder' );
    my $task          = $template_view->CloneVM_Task(
        folder => $folder_view,
        name   => $vmname,
        spec   => $clone_spec
    );
    &VCenter::Task_Status($task);
    &Log::debug("Finishing VCenter::clonevm sub");
    return 1;
}

1
