package VCenter;

use strict;
use warnings;

BEGIN {
    use Exporter;
    our @ISA    = qw( Exporter );
    our @EXPORT = qw( );
}
### Methods
sub clonevm {
    my ( $template, $vmname, $folder, $clone_spec ) = @_;
    &Log::debug(
        "Starting VCenter::clonevm sub, vmname=>'$vmname', folder=>'$folder'");
    my $template_view = &Guest::entity_name_view( $template, 'VirtualMachine' );
    my $folder_view   = &Guest::entity_name_view( $folder,   'Folder' );
    &Log::info("Starting Clone task");
    my $task = $template_view->CloneVM_Task(
        folder => $folder_view,
        name   => $vmname,
        spec   => $clone_spec
    );

    #&Vcenter::Task_getStatus($task);
}

### Helper subs to query information

sub num_check($$) {
    my ( $name, $type ) = @_;
    &Log::debug(
        "Starting VCenter::num_check sub, name=>'$name', type=>'$type'");
    my $views = Vim::find_entity_views(
        view_type  => $type,
        properties => ['name'],
        filter     => { name => $name }
    );
    if ( scalar(@$views) ne 1 ) {
        Entity::NumException->throw(
            error  => 'Entity count not expected',
            entity => $name,
            count  => scalar(@$views)
        );
    }
    &Log::debug("Entity is single");
    return 0;
}

sub exists_entity($$) {
    my ( $name, $type ) = @_;
    &Log::debug(
        "Starting Vcenter::exists_entity sub, name=>'$name', type=>'$type'");
    my $view = Vim::find_entity_view(
        view_type  => $type,
        properties => ['name'],
        filter     => { name => $name }
    );
    if ( defined($view) ) {
        return 1;
    }
    else {
        return 0;
    }
}

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
    &Log::debug("Returning moref");
    return $moref;
}

sub moref2view {
    my ($moref) = @_;
    &Log::debug("Starting VCenter::moref2view sub");
    my $view = Vim::get_view( mo_ref => $moref );
    if ( !defined($view) ) {
        Entity::Status->throw( error => "Could not retrieve view from moref" );
    }
    &Log::debug("Returning view");
    return $view;
}

sub linked_clone_folder {
    my ($temp_name) = @_;
    &Log::debug(
        "Starting Vcenter::linked_clone_folder sub, temp_name=>'$temp_name'");
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

### Subs for creation/deletion

sub create_resource_pool {
    my ( $rp_name, $rp_parent ) = @_;
    &Log::debug(
"Starting VCenter::create_resource_pool sub, rp_name=>'$rp_name', rp_parent=>'$rp_parent'"
    );
    my $type = 'ResourcePool';
    if ( &exists_entity( $rp_name, $type ) ) {
        &Log::debug("Resource pool already exists on Vcenter");
        Entity::NumException->throw(
            error  => 'Resource pool already exists. Cannot create',
            entity => $rp_name,
            count  => '1'
        );
    }
    elsif ( !&exists_entity( $rp_parent, $type ) ) {
        &Log::debug("Resource pool parent doesn't exists on Vcenter");
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
    return $rp_name_view;
}

sub create_folder {
    my ( $fol_name, $fol_parent ) = @_;
    &Log::debug(
"Starting VCenter::create_folder sub, fol_name=>'$fol_name', fol_parent=>'$fol_parent'"
    );
    my $type = 'Folder';
    if ( &exists_entity( $fol_name, $type ) ) {
        &Log::debug("Folder already exists on Vcenter");
        Entity::NumException->throw(
            error  => 'Folder already exists. Cannot create',
            entity => $fol_name,
            count  => '1'
        );
    }
    elsif ( !&exists_entity( $fol_parent, $type ) ) {
        &Log::debug("Folder parent doesn't exists on Vcenter");
        Entity::NumException->throw(
            error  => 'Folder parent doesn\'t exist. Cannot create',
            entity => $fol_parent,
            count  => '0'
        );
    }
    my $fol_parent_view = &Guest::entity_name_view( $fol_parent, 'Folder' );
    &Log::debug("Starting creation of folder in parent");
    my $fol_name_view = $fol_parent_view->CreateFolder( name => $fol_name );
    if ( $fol_name_view->type ne $type ) {
        Entity::NumException->throw(
            error  => 'Could not create folder',
            entity => $fol_name,
            count  => '0'
        );
    }
    &Log::debug("Folder creation was succesful");
    return $fol_name_view;
}

### Subs for connection and buildup to VCenter

sub SDK_options {
    my $opts = shift;
    &Log::debug("Starting VCenter::SDK_options");
    Opts::add_options(%$opts);
    Opts::parse();
    Opts::validate();
}

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
}

sub disconnect_vcenter {
    &Log::debug("Starting VCenter::disconnect_vcenter sub");
    Util::disconnect();
}

sub service_content {
    &Log::debug("Retrieving Service Content object");
    my $sc = Vim::get_service_content();
    if ( !defined($sc) ) {
        Vcenter::ServiceContent->throw(
            error => 'Could not retrieve service content' );
    }
    return $sc;
}
1
__END__