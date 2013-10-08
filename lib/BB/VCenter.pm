package VCenter;

use strict;
use warnings;

BEGIN {
    use Exporter;
    our @ISA    = qw( Exporter );
    our @EXPORT = qw( );
}

=pod

=head1 num_check

=head2 PURPOSE

Checks if the entity only exists once

=head2 PARAMETERS

=back

=item name

Name of the entity

=item type

Type of entity

=over

=head2 RETURNS

True on success

=head2 DESCRIPTION

=head2 THROWS

Entity::NumException if the result is not 1

=head2 COMMENTS

=head2 SEE ALSO

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

=head1 exists_entity

=head2 PURPOSE

Checks if entity exists or not with true or false

=head2 PARAMETERS

=back

=item name

Name of the entity

=item type

Type of entity

=over

=head2 RETURNS

True if entity can be found
False if entity cannot be found

=head2 DESCRIPTION

=head2 THROWS

=head2 COMMENTS

=head2 SEE ALSO

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
    return 1;
}

=pod

=head1 path2name

=head2 PURPOSE

Converts a VCenter inventory path to Name

=head2 PARAMETERS

=back

=item path

VCenter inventory path

=over

=head2 RETURNS

=head2 DESCRIPTION

=head2 THROWS

Vcenter:Path if no entity is found with the requested path

=head2 COMMENTS

=head2 SEE ALSO

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

=head1 path2moref

=head2 PURPOSE

Converts a VCenter inventory path to a Managed object reference

=head2 PARAMETERS

=back

=item path

VCenter inventory path

=over

=head2 RETURNS

=head2 DESCRIPTION

=head2 THROWS

Vcenter:Path if no entity is found with the requested path

=head2 COMMENTS

=head2 SEE ALSO

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

=head1 moref2view

=head2 PURPOSE

Converts a moref to a view

=head2 PARAMETERS

=back

=item moref

A managed object reference

=over

=head2 RETURNS

A Managed object to the reference

=head2 DESCRIPTION

=head2 THROWS

Entity::Status if the get_view returned with undef

=head2 COMMENTS

=head2 SEE ALSO

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

=head1 linked_clone_folder

=head2 PURPOSE

Creates a folder for the template where the linked clones can be stored

=head2 PARAMETERS

=back

=item temp_name

The template name

=over

=head2 RETURNS

A managed object to the folder

=head2 DESCRIPTION

=head2 THROWS

=head2 COMMENTS

=head2 SEE ALSO

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

=head1 check_if_empty_entity

=head2 PURPOSE

Checks if the entity is empty or has children

=head2 PARAMETERS

=back

=item name

Name of entity

=item type

Type of entity

=over

=head2 RETURNS

True if has children
False if entity is empty

=head2 DESCRIPTION

=head2 THROWS

Entity::NumException if no entity found or unknown type is requested

=head2 COMMENTS

=head2 SEE ALSO

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

=head1 Task_Status

=head2 PURPOSE

Checks task status and prints progress

=head2 PARAMETERS

=back

=item taskRef

A Managed object reference to a task

=over

=head2 RETURNS

True on success

=head2 DESCRIPTION

=head2 THROWS

TaskEr::Error if there was an error during the task

=head2 COMMENTS

=head2 SEE ALSO

=cut

sub Task_Status {
    my ($taskRef) = @_;
    &Log::debug("Starting VCenter::Task_Status sub");
    &Log::dumpobj( "taskRef", $taskRef );
## FIXME remove if unneeded
    #my $task_view = Vim::get_view( mo_ref => $taskRef, type => 'Task' );
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

=head1 ticket_vms_name

=head2 PURPOSE

Returns array ref with vmnames attached to a ticket

=head2 PARAMETERS

=back

=item ticket

Ticket number to return names of

=over

=head2 RETURNS

=head2 DESCRIPTION

=head2 THROWS

=head2 COMMENTS

=head2 SEE ALSO

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

=head1 name2path

=head2 PURPOSE

Converts an entity name to VCenter inventory path

=head2 PARAMETERS

=back

=item name

Name of entity whoes name should be converted

=over

=head2 RETURNS

Inventory path of entity

=head2 DESCRIPTION

=head2 THROWS

=head2 COMMENTS

=head2 SEE ALSO

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

=head1 create_resource_pool

=head2 PURPOSE

Creating a resourcepool in requested parent resourcepool

=head2 PARAMETERS

=back

=item rp_name

Name of requested resourcepool

=item rp_parent

Name of requested resourcepool parent

=over

=head2 RETURNS

Managed object of new resourcepool

=head2 DESCRIPTION

=head2 THROWS

Entity::NumException if parent doesn't exist or resourcepool already exists

=head2 COMMENTS

=head2 SEE ALSO

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

=head1 create_folder

=head2 PURPOSE

Create an inventory folder with requested name

=head2 PARAMETERS

=back

=item fol_name

Name of requested folder

=item fol_parent

Parent of requested folder

=over

=head2 RETURNS

Managed object of created folder

=head2 DESCRIPTION

=head2 THROWS

Entity::NumException if requested folder exists or parent doesn't exist

=head2 COMMENTS

=head2 SEE ALSO

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

=head1 create_switch

=head2 PURPOSE

Creates aerquested Distributed Virtual Switch

=head2 PARAMETERS

=back

=item name

Name of requested switch name

=over

=head2 RETURNS

True on success

=head2 DESCRIPTION

=head2 THROWS

Entity::NumException if switch already exists

=head2 COMMENTS

=head2 SEE ALSO

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

=head1 create_dvportgroup

=head2 PURPOSE

Create a requested Distributed Virtual Portgroup

=head2 PARAMETERS

=back

=item name

Requested name for distributed virtual Portgroup

=item switch

Parent switch for portgroup

=over

=head2 RETURNS

True on success

=head2 DESCRIPTION

=head2 THROWS

Entity::NumException if entity already exists

=head2 COMMENTS

=head2 SEE ALSO

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

=head1 destroy_entity

=head2 PURPOSE

Destroy a requested entity type

=head2 PARAMETERS

=back

=item name

Name of entity to destroy

=item type

Type of entity

=over

=head2 RETURNS

True on success

=head2 DESCRIPTION

=head2 THROWS

Entity::NumException if delete was not succesful

=head2 COMMENTS

=head2 SEE ALSO

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

=head1 vm_last_snapshot_view

=head2 PURPOSE

Returns last snapshot for a vm

=head2 PARAMETERS

=back

=item vmname

Virtual Machine name

=over

=head2 RETURNS

Managed object of requested snapshot

=head2 DESCRIPTION

Sub only handles one tier at level 0!
Reason: If a sceneraio requires that the initial disk have multiple snapshot for different uses, than
than is a fubar and should be handled with multiple machines. There can be later recursions to different points
but it should not diverge deeply and create multi depth hiearchy for snapshots. To handle these are not
trivial and not best practices. A snapshot should be used for short times and deleted afterwards

=head2 THROWS

Entity::Snapshot if virtual machine has no snapshots defined

=head2 COMMENTS

=head2 SEE ALSO

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
    &Log::dumpbobj( "snapshot_view", $snapshot_view );
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

=head1 find_vms_with_disk

=head2 PURPOSE

Returns array ref with all machines linked to a vmdk disk

=head2 PARAMETERS

=back

=item disk

A datastore path to a vmdk file

=over

=head2 RETURNS

Array ref with all virtual machines linked to the disk

=head2 DESCRIPTION

=head2 THROWS

=head2 COMMENTS

=head2 SEE ALSO

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

=head1 datastore_file_exists

=head2 PURPOSE

Checks if datastore file exists

=head2 PARAMETERS

=back

=item filename

Datastore path to file

=over

=head2 RETURNS

True if file exists
False if file does not exist

=head2 DESCRIPTION

=head2 THROWS

=head2 COMMENTS

=head2 SEE ALSO

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
    my $ret = 0
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

=head1 SDK_options

=head2 PURPOSE

For parsing SDK options and feeding the

=head2 PARAMETERS

=back

=item opts

A hash ref to the options that should be added

=over

=head2 RETURNS

True on success

=head2 DESCRIPTION

=head2 THROWS

=head2 COMMENTS

=head2 SEE ALSO

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

=head1 connect_vcenter

=head2 PURPOSE

Connecting to a VCenter

=head2 PARAMETERS

=back

=over

=head2 RETURNS

True on success

=head2 DESCRIPTION

=head2 THROWS

Connection::Connect if connection to VCenter fails

=head2 COMMENTS

=head2 SEE ALSO

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

=head1 disconnect_vcenter

=head2 PURPOSE

Disconnects from VCenter

=head2 PARAMETERS

=back

=over

=head2 RETURNS

True on success

=head2 DESCRIPTION

=head2 THROWS

=head2 COMMENTS

=head2 SEE ALSO

=cut

sub disconnect_vcenter {
    &Log::debug("Starting VCenter::disconnect_vcenter sub");
    Util::disconnect();
    &Log::debug("Finishing VCenter::disconnect_vcenter sub");
    return 1;
}

=pod

=head1 service_content

=head2 PURPOSE

Retrieves service content

=head2 PARAMETERS

=back

=over

=head2 RETURNS

Managed Object for a service content

=head2 DESCRIPTION

=head2 THROWS

Vcenter::ServiceContent if service content could not be retrieved

=head2 COMMENTS

=head2 SEE ALSO

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

=head1 move_into_folder

=head2 PURPOSE

Moves a Virtual Machine into a folder

=head2 PARAMETERS

=back

=item vmname

Virtual Machine name

=item folder

The requested folder

=over

=head2 RETURNS

True on success

=head2 DESCRIPTION

=head2 THROWS

=head2 COMMENTS

=head2 SEE ALSO

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

=head1 get_vim

=head2 PURPOSE

Retrieves a vim object

=head2 PARAMETERS

=back

=over

=head2 RETURNS

Vim object

=head2 DESCRIPTION

=head2 THROWS

Vcenter::ServiceContent if vim objcect could not be retrieved

=head2 COMMENTS

=head2 SEE ALSO

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

=head1 get_manager

=head2 PURPOSE

Retrieve SErvice content manager

=head2 PARAMETERS

=back

=item type

Type of manager to retrieve
Possible values: accountManager, authManager, authorizationManager, clusterProfileManager, complianceManager, customFieldsManager, customizationSpecManager, diagnosticManager, dvSwitchManager, eventManager,
extensionManager, fileManager, hostProfileManager, ipPoolManager, licenseManager, localizationManager, ovfManager, perfManager, propertyCollector, rootFolder, scheduledTaskManager, searchIndex, sessionManager,
setting, snmpSystem, storageResourceManager, taskManager, userDirectory, viewManager, virtualDiskManager, virtualizationManager, vmCompatibilityChecker, vmProvisioningChecker

Undocumented : guestOperationsManager

=over

=head2 RETURNS

The Service content object requested

=head2 DESCRIPTION

=head2 THROWS

Vcenter::ServiceContent if no object is found with requested name

=head2 COMMENTS

=head2 SEE ALSO

=cut

sub get_manager {
    my ($type) = @_;
    &Log::debug("Starting VCenter::get_manager sub");
    &Log::debug1("Opts are: type=>'$type'");
    my $manager = &VCenter::moref2view( &VCenter::service_content->{$type} );
    &Log::dumpobj( $type, $manager );
    if ( !defined($guestOM) ) {
        Vcenter::ServiceContent->throw(
            error => "Could not retrieve $type Manager" );
    }
    &Log::debug("Finishing VCenter::get_manager sub");
    return $manager;
}

1
