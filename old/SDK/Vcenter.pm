package Vcenter;

use strict;
use warnings;
use Data::Dumper;
use SDK::Misc;
use SDK::Support;
use SDK::Error;

BEGIN {
	use Exporter;
	our @ISA = qw( Exporter );
	our @EXPORT = qw( &test &mac_compare &Task_getStatus &delete_virtualmachine &check_if_empty_resource_pool &delete_resource_pool &exists_resource_pool &list_resource_pool_rp &print_resource_pool_content &print_folder_content &check_if_empty_folder &exists_vm &datastore_file_exists &entity_exists &get_names &num_check );
}

## Searches all virtual machines mac address if mac address is already used
## Parameters:
##  mac: mac address to search format: xx:xx:xx:xx:xx:xx
## Returns:
##  true or false according to success

sub mac_compare {
	my ( $mac ) = @_;
	Util::trace( 4, "Starting Vcenter::mac_compare sub, mac=>'$mac'\n" );
	my $vm_view = Vim::find_entity_views( view_type => 'VirtualMachine', properties => [ 'config.hardware.device', 'summary.config.name' ] );
	foreach( @$vm_view ) {
		my $vm_name = $_->get_property( 'summary.config.name' );
		my $devices =$_->get_property( 'config.hardware.device' );
		foreach( @$devices ) {
			if( $_->isa( "VirtualEthernetCard" ) ) {
				if ( $mac eq $_->macAddress ) {
					Util::trace( 4, "Finished Vcenter::mac_compare sub, mac found\n" );
					return 1;
				}
			}
		}
	}
	Util::trace( 4, "Finished Vcenter::mac_compare sub, no mac found\n" );
	return 0;
}

sub delete_virtualmachine {
	my ( $vmname ) = @_;
	Util::trace( 4, "Starting Vcenter::delete_virtualmachine sub, vmname=>'$vmname'\n" );
	&num_check( $vmname, 'VirtualMachine' );
	my $view = Vim::find_entity_view( view_type => 'VirtualMachine', properties => [ 'runtime->powerState->val' ] ,filter => { name => $vmname } );
	my $powerstate = $view->runtime->powerState->val;
	if ( $powerstate eq 'poweredOn' ) {
		Util::trace( 1, "Powering off VM\n" );
		my $task = $view->PowerOffVM_Task;
		&Task_getStatus( $task );
	}
	my $task = $view->Destroy_Task;
	&Task_getStatus( $task );
	$view = Vim::find_entity_views( view_type => 'VirtualMachine', properties => [ 'name' ] ,filter => { name => $vmname } );
	if ( scalar(@$view) ne 0 ) {
		SDK::Error::Entity::Exists->throw( error => 'Could not delete virtual machine', entity => $vmname );
	}
	Util::trace( 4, "VM deleted succesfully, vmname=>'$vmname'\n" );
}

sub Task_getStatus {
	my ( $taskRef ) = @_;
	Util::trace( 4, "Starting Vcenter::Task_getStatus\n" );
	my $task_view = Vim::get_view( mo_ref => $taskRef );
	if ( !defined( $task_view ) ) {
		SDK::Error::Task::NotDefined->throw( error => 'No task_view found for reference' );
	}
	my $continue = 1;
	while ( $continue ) {
		if ( defined( $task_view->info->progress ) ) {
			Util::trace( 0, "Currently at " . $task_view->info->progress . "%\n" );
		}
		if ( $task_view->info->state->val eq 'success' ) {
			$continue = 0;
		} elsif ( $task_view->info->state->val eq 'error' ) {
			SDK::Error::Task::Error->throw( error=> 'Error happened during task', detail => $task_view->info->error->fault, fault => $task_view->info->error->localizedMessage );
		}
		sleep 1;
		$task_view->ViewBase::update_view_data( );
	}
	Util::trace( 4, "Finished Vcenter::Task_getStatus\n" );
}

sub check_if_empty_switch {
	my ( $name ) = @_;
	Util::trace( 4, "Starting Vcenter::check_if_empty_switch sub, name=>'$name'\n" );
	my $view = Vim::find_entity_view( view_type => 'DistributedVirtualSwitch', properties => [ 'summary.portgroupName', 'name' ], filter => { name => $name } );
	if ( !defined( $view ) ) {
		SDK::Error::Entity::NumException->throw( error => 'Switch does not exist', entity => $name, count => '0' );
	}
	my $count = $view->get_property('summary.portgroupName');
	Util::trace( 5, "My count is=>@$count\n" );
	if ( @$count < 2 ) {
		Util::trace( 4, "Finished Vcenter::check_if_empty_switch sub, return=>'true'\n" );
		return 1;
	} else {
		Util::trace( 4, "Finished Vcenter::check_if_empty_switch sub, return=>'false'\n" );
		return 0;
	}
}

sub check_if_empty_resource_pool {
	my ( $name ) = @_;
	Util::trace( 4, "Starting Vcenter::check_if_empty_resource_pool sub, name=>'$name'\n" );
	my $view = Vim::find_entity_view( view_type => 'ResourcePool', properties => [ 'name', 'vm', 'resourcePool' ], filter => { name => $name } );
	if ( !defined( $view ) ) {
		SDK::Error::Entity::NumException->throw( error => 'Resourcepool does not exis', entity => $name, count => '0' );
	}
	if ( !defined( $view->vm ) and !defined( $view->resourcePool ) ) {
		Util::trace( 4, "Finished Vcenter::check_if_empty_resource_pool sub, return=>'true'\n" );
		return 1;
	} else {
		Util::trace( 4, "Finished Vcenter::check_if_empty_resource_pool sub, return=>'false'\n" );
		return 0;
	}
}

sub check_if_empty_folder {
	my ( $name ) = @_;
	Util::trace( 4, "Starting Vcenter::check_if_empty_folder sub, name=>'$name'\n" );
	my $view = Vim::find_entity_view( view_type => 'Folder', properties => [ 'name', 'childEntity' ], filter => { name => $name } );
	if ( !defined( $view ) ) {
		SDK::Error::Entity::NumException->throw( error => 'Folder does not exis', entity => $name, count => '0' );
	}
	if ( !defined( $view->childEntity ) ) {
		Util::trace( 4, "Finished Vcenter::check_if_empty_folder sub, return=>'true'\n" );
		return 1;
	} else {
		Util::trace( 4, "Finished Vcenter::check_if_empty_folder sub, return=>'false'\n" );
		return 0;
	}
}

sub delete_folder {
	my ( $name ) = @_;
	Util::trace( 4, "Starting Vcenter::delete_folder sub, name=>'$name'\n" );
	my $view = Vim::find_entity_view( view_type => 'Folder', properties => [ 'name' ], filter => { name => $name } );
	if ( &check_if_empty_folder( $name ) ) {
		my $task = $view->Destroy_Task;
		&Task_getStatus( $task );
	}
	$view = Vim::find_entity_views( view_type => 'Folder', properties => [ 'name' ] ,filter => { name => $name } );
	if ( scalar(@$view) ne 0 ) {
		SDK::Error::Entity::Exists->throw( error => 'Could not delete folder', entity => $name );
	}
	Util::trace( 4, "Finished Vcenter::delete_folder sub\n" );
}

sub delete_resource_pool {
	my ( $name ) = @_;
	Util::trace( 4, "Starting Vcenter::delete_resource_pool sub, name=>'$name'\n" );
	my $view = Vim::find_entity_view( view_type => 'ResourcePool', properties => [ 'name' ], filter => { name => $name } );
	if ( &check_if_empty_resource_pool( $name ) ) {
		my $task = $view->Destroy_Task;
		&Task_getStatus( $task );
	}
	$view = Vim::find_entity_view( view_type => 'ResourcePool', properties => [ 'name' ], filter => { name => $name } );
	if ( scalar(@$view) ne 0 ) {
		SDK::Error::Entity::Exists->throw( error => 'Could not delete resource pool', entity => $name );
	}
	Util::trace( 4, "Finished Vcenter::delete_resource_pool sub\n" );
}


sub get_name_from_moref {
	my ( $name ) = @_;
	Util::trace( 4, "Starting Vcenter::get_name_from_moref sub\n" );
	my $view = Vim::get_view( mo_ref => $name );
	if ( !defined( $view ) ) {
		SDK::Error::Entity::NumException->throw( error => 'Could not retrieve name for mo ref', entity => $name, count => '0' );
	}
	Util::trace( 4, "Finished Vcenter::get_name_from_moref\n" );
	return $view->name;
}

sub list_resource_pool_vms {
	my ( $name ) = @_;
	Util::trace( 4, "Starting Vcenter::list_resource_pool_vms sub, name=>'$name'\n" );
	if ( !&exists_resource_pool( $name ) ) {
		Util::trace( 4, "Resource pool does not exist\n" );
		return 0;
	}
	my $view = Vim::find_entity_view( view_type => 'ResourcePool', properties => [ 'vm' ], filter => { name => $name } );
	my $vms = $view->get_property('vm');
	my @names;
	foreach ( @$vms ) {
		push( @names, &get_name_from_moref( $_ ) );
	}
	if ( scalar( @names) gt 0 ) {
		Util::trace( 4, "Finished Vcenter::list_resource_pool sub, returning names\n" );
		return @names;
	} else {
		Util::trace( 4, "Finished Vcenter::list_resource_pool sub, no vms listed\n" );
		return 0;
	}
}

sub list_folder_vms {
	my ( $name ) = @_;
	Util::trace( 4, "Starting Vcenter::list_folder_vms sub, name=>'$name'\n" );
	if ( !&exists_folder( $name ) ) {
		Util::trace( 4, "Folder does not exist\n" );
		return 0;
	}
	my $view = Vim::find_entity_view( view_type => 'Folder', properties => [ 'childEntity' ], filter => { name => $name } );
	my $vms = $view->childEntity;
	my @names;
	foreach ( @$vms ) {
		if ( $_->type eq 'VirtualMachine' ) {
			push( @names, &get_name_from_moref( $_ ) );
		}
	}
	if ( scalar( @names) gt 0 ) {
		Util::trace( 4, "Finished Vcenter::list_folder_vms sub, returning names\n" );
		return @names;
	} else {
		Util::trace( 4, "Finished Vcenter::list_folder_vms sub, no names found\n" );
		return 0;
	}
}


sub list_resource_pool_rp {
	my ( $name ) = @_;
	Util::trace( 4, "Starting Vcenter::list_resource_pool_rp sub, name=>'$name'\n" );
	if ( !&exists_resource_pool( $name ) ) {
		Util::trace( 4, "Resource pool does not exist\n" );
		return 0;
	}
	my $view = Vim::find_entity_view( view_type => 'ResourcePool', properties => [ 'resourcePool' ], filter => { name => $name } );
	my $rps = $view->resourcePool;
	my @names;
	foreach ( @$rps ) {
		push( @names, &get_name_from_moref( $_ ) );
	}
	if ( scalar( @names ) gt 0 ) {
		Util::trace( 4, "Finished Vcenter::list_resource_pool_rp sub, returning names\n" );
		return @names;
	} else {
		Util::trace( 4, "Finished Vcenter::list_resource_pool_rp sub, no rp-s found\n" );
		return 0;
	}
}

sub list_folder_folders {
	my ( $name ) = @_;
	Util::trace( 4, "Starting Vcenter::list_folder_folders sub, name=>'$name'\n" );
	if ( !&exists_folder( $name ) ) {
		Util::trace( 4, "Folder does not exist\n" );
		return 0;
	}
	my $view = Vim::find_entity_view( view_type => 'Folder', properties => [ 'childEntity' ], filter => { name => $name } );
	my $folders = $view->childEntity;
	my @names;
	foreach ( @$folders ) {
		if ( $_->type eq 'Folder' ) {
			push( @names, &get_name_from_moref( $_ ) );
		}
	}
	if ( scalar( @names ) gt 0 ) {
		Util::trace( 4, "Finished Vcenter::list_folder_folders sub, returning names\n" );
		return @names;
	} else {
		Util::trace( 4, "Finished Vcenter::list_folder_folders sub, nothing found\n" );
		return 0;
	}
}

sub print_resource_pool_content {
	my ( $name ) = @_;
	Util::trace( 4, "Starting Vcenter::print_resource_pool_content sub, name=>'$name'\n" );
	if ( &exists_resource_pool( $name ) ) {
		Util::trace( 0, "Resource pool:$name\n" );
		Util::trace( 0, "=" x 80 . "\n" );
		my @vms = &list_resource_pool_vms( $name );
		my @rps = &list_resource_pool_rp( $name );
		foreach ( @rps ) {
			Util::trace( 0, "Resource Pool:'$_'\n" );
		}
		foreach ( @vms ) {
			Util::trace( 0, "VM:'$_'\n" );
		}
		Util::trace( 0, "=" x 80 . "\n" );
		Util::trace( 0, "=" x 80 . "\n" );
	} else {
		SDK::Error::Entity::NumException->throw( error => 'Resource pool not exists', entity => $name, count => '0' );
	}
	Util::trace( 4, "Finished Vcenter::print_resource_pool_content sub\n" );

}

sub print_folder_content {
	my ( $name ) = @_;
	Util::trace( 4, "Starting Vcenter::print_folder_content sub, name=>'$name'\n" );
	if ( &exists_folder( $name ) ) {
		Util::trace( 0, "Inventory Folder:$name\n" );
		Util::trace( 0, "=" x 80 . "\n" );
		my @vms = &list_folder_vms( $name );
		my @folders = &list_folder_folders( $name );
		foreach ( @folders ) {
			Util::trace( 0, "Folders:'$_'\n" );
		}
		foreach ( @vms ) {
			Util::trace( 0, "VM:'$_'\n" );
		}
		Util::trace( 0, "=" x 80 . "\n" );
		Util::trace( 0, "=" x 80 . "\n" );
	} else {
		SDK::Error::Entity::NumException->throw( error => 'Folder not exists', entity => $name, count => '0' );
	}
	Util::trace( 4, "Finished Vcenter::print_folder_content sub\n" );
}

sub print_vm_info {
	my ( $name ) = @_;
	Util::trace( 4, "Starting Vcenter::print_vm_info sub, name=>'$name'\n" );
	my $view;
	if ( &exists_vm( $name ) ) {
		$view = Vim::find_entity_view( view_type => 'VirtualMachine', properties => [ 'name', 'guest' ], filter => { name => $name } );
	} else {
		SDK::Error::Entity::NumException->throw( error => 'Could not find VM', entity => $name, count => '0' );
	}
	Util::trace( 0, "VMname:'" . $view->name ."'\n" );
	Util::trace( 0, "\tPower State:'" . $view->guest->guestState . "'\n" );
	Util::trace( 0, "\tAlternate name: '" . &GuestManagement::get_altername( $view->name ) . "'\n" );
	if ( $view->guest->toolsStatus eq 'toolsNotInstalled' ) {
		Util::trace( 4, "\tTools not installed. Cannot extract some information\n" );
	} else {
		if ( defined( $view->guest->net ) ) {
			foreach ( @{ $view->guest->net } ) {
				if ( defined( $_->ipAddress ) ) {
					Util::trace( 0, "\tNetwork => '" . $_->network. "', with ipAddresses => [ " .join( ", ", @{ $_->ipAddress } ) . " ]\n" );
				} else {
					Util::trace( 0, "\tNetwork => '" . $_->network. "'\n" );
				}
			}
			if ( defined( $view->guest->hostName ) ) {
				Util::trace( 0, "\tHostname: '" . $view->guest->hostName . "'\n" );
			}
		} else {
			Util::trace( 0, "\tNo network information available\n" );
		}
	}
	my ( $ticket, $username, $family, $version, $lang, $arch, $type , $uniq ) = &Misc::vmname_splitter( $view->name );
	my $os;
	if ( $type =~ /xcb/ ) {
		$os = "${ family }_${ version }";
	} else {
		$os = "${ family }_${ version }_${ lang }_${ arch }_${ type }";
	}
	if ( defined( $uniq )  ) {
		if ( defined( $Support::template_hash{ $os } ) ) {
			my $guestusername =$Support::template_hash{ $os }{ 'username' };
			my $guestpassword =$Support::template_hash{ $os }{ 'password' };
			Util::trace( 0, "\tDefault login : $guestusername / $guestpassword\n" );
		} else {
			Util::trace( 0, "\tRegex matched an OS, but no template found to it os => '$os'\n" );
		}
	} else {
		Util::trace( 0, "\tVmname not standard name => '$name'\n" );
	}
	Util::trace( 4, "Finished Vcenter::print_vm_info sub\n" );
}

sub datastore_file_exists {
	my ( $filename ) = @_;
	Util::trace( 4, "Starting Vcenter::datastore_file_exists sub, filename=>'$filename'\n" );
	my ( $datas, $folder, $image ) = &Misc::filename_splitter( $filename );
	my $datastore = Vim::find_entity_view( view_type => 'Datastore', properties => [ 'browser' ], filter => { name => $datas } );
	if ( !defined( $datastore ) ) {
		SDK::Error::Entity::NumException->throw( error => 'Could not find datastore', entity => $datas, count => '0' );
	}
	my $browser = Vim::get_view( mo_ref => $datastore->browser );
	my $files = FileQueryFlags->new( fileSize => 0, fileType => 1, modification => 0, fileOwner => 0 );
	my $searchspec = HostDatastoreBrowserSearchSpec->new( details => $files, matchPattern => [ $image ] );
	my $return = $browser->SearchDatastoreSubFolders( datastorePath => "[ $datas ] $folder", searchSpec => $searchspec );
	if ( defined( $return->[ 0 ]->file ) ) {
		Util::trace( 4, "Finishing Vcenter::datastore_file_exists sub, return=>'File Found'\n" );
		return 1;
	} else {
		Util::trace( 4, "Finishing Vcenter::datastore_file_exists sub, return=>'File not Found'\n" );
		return 0;
	}

}

1