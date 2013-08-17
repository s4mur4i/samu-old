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
	my $vm_view = Vim::find_entity_views( view_type => 'VirtualMachine', properties => [ 'config.hardware.device', 'summary.config.name' ] );

	foreach( @$vm_view ) {
		my $vm_name = $_->get_property( 'summary.config.name' );
		my $devices =$_->get_property( 'config.hardware.device' );
		foreach( @$devices ) {
			if( $_->isa( "VirtualEthernetCard" ) ) {
				if ( $mac eq $_->macAddress ) {
					return 1;
				}
			}
		}
	}
	return 0;
}

sub delete_virtualmachine {
	my ( $vmname ) = @_;
	&num_check( $vmname, 'VirtualMachine' );
	my $view = Vim::find_entity_view( view_type => 'VirtualMachine', properties => [ 'runtime->powerState->val' ] ,filter => { name => $vmname } );
	my $powerstate = $view->runtime->powerState->val;
	if ( $powerstate eq 'poweredOn' ) {
		print "Powering off VM.\n";
		my $task = $view->PowerOffVM_Task;
		&Task_getStatus( $task );
	}
	my $task = $view->Destroy_Task;
	&Task_getStatus( $task );
	$view = Vim::find_entity_views( view_type => 'VirtualMachine', properties => [ 'name' ] ,filter => { name => $vmname } );
	if ( scalar(@$view) ne 0 ) {
		SDK::Error::Entityi::Exists->throw( error => 'Could not delete virtual machine', entity => $vmname );
	}
	print "Vm deleted succsfully: " . $view->name . "\n";
}

sub Task_getStatus {
	my ( $taskRef ) = @_;
	my $task_view = Vim::get_view( mo_ref => $taskRef );
	if ( !defined( $task_view ) ) {
		SDK::Error::Task::NotDefined->throw( error => 'No task_view found for reference' );
	}
	#my $taskinfo = $task_view->info->state->val;
	my $continue = 1;
	while ( $continue ) {
		print Dumper($task_view);
		#my $info = $task_view->info;
		if ( $task_view->info->state->val eq 'success' ) {
			$continue = 0;
		} elsif ( $info->state->val eq 'error' ) {
		#	my $soap_fault = SoapFault->new;
		#	$soap_fault->name( $info->error->fault );
		#	$soap_fault->detail( $info->error->fault );
		#	$soap_fault->fault_string( $info->error->localizedMessage );
		#	die "$soap_fault\n";
			SDK::Error::Task::Error->throw( error=> 'Error happened during task', detail => $task_view->info->error->fault, fault => $task_view->info->error->localizedMessage );
		}
		sleep 1;
		$task_view->ViewBase::update_view_data( );
	}
}

sub check_if_empty_switch {
	my ( $name ) = @_;
	my $view = Vim::find_entity_view( view_type => 'DistributedVirtualSwitch', propertiesv=> [ 'summary->portgroupName' ], filter => { name => $name } );
	if ( !defined( $view ) ) {
		SDK::Error::Entity::NumException->throw( error => 'Switch does not exist', entity => $name, count => '0' );
	}
	my $count = $name->summary->portgroupName;
	if ( scalar( @$count ) < 2 ) {
		return 1;
	} else {
		return 0;
	}
}

sub check_if_empty_resource_pool {
	my ( $name ) = @_;
	$name = Vim::find_entity_view( view_type => 'ResourcePool', filter => { name => $name } );
	if ( !defined( $name ) ) {
		print "No such resource pool.\n";
		return 0;
	}
	if ( defined( $name->vm ) ) {
		return 0;
	} else {
		if ( defined( $name->resourcePool ) ) {
			return 0;
		} else {
			return 1;
		}
	}
}

sub check_if_empty_folder {
	my ( $name ) = @_;
	$name = Vim::find_entity_view( view_type => 'Folder', filter => { name => $name } );
	if ( !defined( $name ) ) {
		print "No such folder.\n";
		return 0;
	}
	if ( !defined( $name->childEntity ) ) {
		return 1;
	} else {
		return 0;
	}
}

sub delete_folder {
	my ( $name ) = @_;
	if ( &check_if_empty_folder( $name ) ) {
		$name = Vim::find_entity_view( view_type => 'Folder', filter => { name => $name } );
		my $task = $name->Destroy_Task;
		&Task_getStatus( $task );
	}
}

sub delete_resource_pool {
	my ( $name ) = @_;
	if ( &check_if_empty_resource_pool( $name ) ) {
		$name = Vim::find_entity_view( view_type => 'ResourcePool', filter => { name => $name } );
		my $task = $name->Destroy_Task;
		&Task_getStatus( $task );
	}
}

sub exists_resource_pool {
	my ( $name ) = @_;
	my $rp_view = Vim::find_entity_view( view_type => 'ResourcePool', filter => { name => $name } );
	if ( defined( $rp_view ) ) {
		return 1;
	}else {
		return 0;
	}
}

sub exists_vm {
	my ( $name ) = @_;
	my $vm = Vim::find_entity_view( view_type => 'VirtualMachine', filter => { name => $name } );
	if ( defined( $vm ) ) {
		return 1;
	}else {
		return 0;
	}
}

sub exists_folder {
	my ( $name ) = @_;
	my $folder_view = Vim::find_entity_view( view_type => 'Folder', filter => { name => $name } );
	if ( defined( $folder_view ) ) {
		return 1;
	}else {
		return 0;
	}
}

## FIXME: Pull the subs together..same function
sub get_vmname_from_moref {
	my ( $name ) = @_;
	my $view = Vim::get_view( mo_ref => $name );
	## FIXME implement check to validate if anything is returned.
	return $view->name;
}

sub get_rpname_from_moref {
	my ( $name ) = @_;
	my $view = Vim::get_view( mo_ref => $name );
	## FIXME implement check to validate if anything is returned.
	return $view->name;
}

sub get_folder_name_from_moref {
	my ( $name ) = @_;
	my $view = Vim::get_view( mo_ref => $name );
	## FIXME implement check to validate if anything is returned.
	return $view->name;
}

sub list_resource_pool_vms {
	my ( $name ) = @_;
	if ( !&exists_resource_pool( $name ) ) {
		return 0;
	}
	my $rp_view = Vim::find_entity_view( view_type => 'ResourcePool', filter => { name => $name } );
	my $vms = $rp_view->vm;
	my @names;
	foreach ( @$vms ) {
		push( @names, &get_vmname_from_moref( $_ ) );
	}
	return @names;
}

sub list_folder_vms {
	my ( $name ) = @_;
	if ( !&exists_folder( $name ) ) {
		return 0;
	}
	my $folder_view = Vim::find_entity_view( view_type => 'Folder', filter => { name => $name } );
	my $vms = $folder_view->childEntity;
	my @names;
	foreach ( @$vms ) {
		if ( $_->type eq 'VirtualMachine' ) {
			push( @names, &get_vmname_from_moref( $_ ) );
		}
	}
	return @names;
}


sub list_resource_pool_rp {
	my ( $name ) = @_;
	if ( !&exists_resource_pool( $name ) ) {
		return 0;
	}
	my $rp_view = Vim::find_entity_view( view_type => 'ResourcePool', filter => { name => $name } );
	my $rps = $rp_view->resourcePool;
	my @names;
	foreach ( @$rps ) {
		push( @names, &get_rpname_from_moref( $_ ) );
	}
	return @names;
}

sub list_folder_folders {
	my ( $name ) = @_;
	if ( !&exists_folder( $name ) ) {
		return 0;
	}
	my $folder_view = Vim::find_entity_view( view_type => 'Folder', filter => { name => $name } );
	my $folders = $folder_view->childEntity;
	my @names;
	foreach ( @$folders ) {
		if ( $_->type eq 'Folder' ) {
			push( @names, &get_folder_name_from_moref( $_ ) );
		}
	}
	return @names;
}


sub print_resource_pool_content {
	my ( $name ) = @_;
	if ( &exists_resource_pool( $name ) ) {
		print "Resource pool:$name\n";
		print " =" x 80 . "\n";
		my @vms = &list_resource_pool_vms( $name );
		my @rps = &list_resource_pool_rp( $name );
		foreach ( @rps ) {
			print "Resource Pool:'$_'\n";
		}
		foreach ( @vms ) {
			print "VM:'$_'\n";
		}
		print " =" x 80 . "\n";
		print " =" x 80 . "\n";
	} else {
		print "Resource pool doesn't exist\n";
		return 3;
	}

}

sub print_folder_content {
	my ( $name ) = @_;
	if ( &exists_folder( $name ) ) {
		print "Inventory Folder:$name\n";
		print " =" x 80 . "\n";
		my @vms = &list_folder_vms( $name );
		my @folders = &list_folder_folders( $name );
		foreach ( @folders ) {
			print "Folders:'$_'\n";
		}
		foreach ( @vms ) {
			print "VM:'$_'\n";
		}
		print " =" x 80 . "\n";
		print " =" x 80 . "\n";
	} else {
		print "Folder doesn't exist\n";
		return 3;
	}

}


sub create_resource_pool {
	my ( $name, $parent ) = @_;
	if ( &exists_resource_pool( $name ) ) {
		print "Resource pool already exists.\n";
		return 0;
	}
	$parent = Vim::find_entity_view( view_type => 'ResourcePool', filter => { name => $parent } );
	my $shareslevel = SharesLevel->new( 'normal' );
	my $cpushares = SharesInfo->new( shares => 4000 , level => $shareslevel );
	my $memshares = SharesInfo->new( shares => 32928, level => $shareslevel );
	my $cpuallocation = ResourceAllocationInfo->new( expandableReservation => 'true', limit => -1, reservation => 0, shares => $cpushares );
	my $memoryallocation = ResourceAllocationInfo->new( expandableReservation => 'true', limit => -1, reservation => 0, shares => $memshares );
	my $rp_spec = ResourceConfigSpec->new( cpuAllocation => $cpuallocation, memoryAllocation => $memoryallocation );
	my $name_view = $parent->CreateResourcePool( name => $name, spec => $rp_spec );
	if( $name_view->type eq 'ResourcePool' ) {
		print "Successfully created new ResourcePool: \"" . $name . "\"\n";
		return 1;
	} else {
		print "Error: Unable to create new ResourcePool: \"" . $name . "\"\n";
		return 0;
	}
	return 0;
}

sub create_folder {
	my ( $name, $parent ) = @_;
	if ( &exists_folder( $parent ) ) {
		$parent = Vim::find_entity_view( view_type => 'Folder', filter => { name => $parent } );
	}
	if ( &exists_folder( $name ) ) {
		print "Folder already exists.\n";
		return 0;
	}
	my $new_folder = $parent->CreateFolder( name => $name );
	if( $new_folder->type eq 'Folder' ) {
		print "Successfully created new Folder: \"" . $name . "\"\n";
		return 1;
	} else {
		print "Error: Unable to create new Folder: \"" . $name . "\"\n";
		return 0;
	}
	return 0;
}

sub path_to_moref {
	my ( $path ) = @_;
	my $sc = Vim::get_service_content( );
	my $searchindex = Vim::get_view( mo_ref => $sc->searchIndex );
	my $template_mo_ref = $searchindex->FindByInventoryPath( inventoryPath => $path );
	$template_mo_ref = Vim::get_view( mo_ref => $template_mo_ref );
	return $template_mo_ref;
}

sub print_vm_info {
	my ( $name ) = @_;
	if ( &exists_vm( $name ) ) {
		$name = Vim::find_entity_view( view_type => 'VirtualMachine', filter => { name => $name } );
	} else {
		return 0;
	}
	print "VMname: '" .$name->name ."'\n";
	print "\tPower State: '" .$name->guest->guestState . "'\n";
	print "\tAlternate name: '" . &GuestManagement::get_altername( $name->name ). "'\n";
	if ( $name->guest->toolsStatus eq 'toolsNotInstalled' ) {
		print "\tTools not installed. Cannot extract some information\n";
	} else {
		if ( defined( $name->guest->net ) ) {
			foreach ( @{ $name->guest->net } ) {
				if ( defined( $_->ipAddress ) ) {
					print "\tNetwork => '" . $_->network. "', with ipAddresses => [ " .join( ", ", @{ $_->ipAddress } ) . " ]\n";
				} else {
					print "\tNetwork => '" . $_->network. "'\n";
				}
			}
			if ( defined( $name->guest->hostName ) ) {
				print "\tHostname: '" . $name->guest->hostName . "'\n";
			}
		} else {
			print "\tNo network information available\n";
		}
	}
	my ( $ticket, $username, $family, $version, $lang, $arch, $type , $uniq ) = &Misc::vmname_splitter( $name->name );
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
			print "\tDefault login : $guestusername / $guestpassword\n"
		} else {
			print "\tRegex matched an OS, but no template found to it os => '$os'\n";
		}
	} else {
		print "\tVmname not standard name => '$name'\n";
	}
}

sub datastore_file_exists {
	my ( $filename ) = @_;
	my ( $datas, $folder, $image ) = &Misc::filename_splitter( $filename );
	my $datastore = Vim::find_entity_view( view_type => 'Datastore', filter => { name => $datas } );
	my $browser = Vim::get_view( mo_ref => $datastore->browser );
	my $files = FileQueryFlags->new( fileSize => 0, fileType => 1, modification => 0, fileOwner => 0 );
	my $searchspec = HostDatastoreBrowserSearchSpec->new( details => $files, matchPattern => [ $image ] );
	my $return = $browser->SearchDatastoreSubFolders( datastorePath => "[ $datas ] $folder", searchSpec => $searchspec );
	if ( defined( $return->[ 0 ]->file ) ) {
		print "File found\n";
		return 1;
	} else {
		print "File not found\n";
		return 0;
	}

}

sub entity_exists {
	my ( $type, $name ) =@_;
	my $views = Vim::find_entity_views( view_type => $type, properties => [ 'name' ], filter => { name => $name } );
	if ( defined( $views ) ) {
		return 1;
	} else {
		return 0;
	}
}

sub get_names {
	my ( $type, $name ) =@_;
	my @names;
	my $views = Vim::find_entity_views( view_type => $type, properties => [ 'name' ], filter => { name => qr/*$name*/ } );
	if ( &entity_exists( $type, $name ) ) {
		foreach ( @$views ) {
			push( @names, $_->name );
		}
		return @names;
	} else {
		print "No entities found with name: $name";
		return 0;
	}
}

sub num_check {
	my ( $vmname, $type ) = @_;
	my $views = Vim::find_entity_views( view_type => $type, properties => [ 'name' ], filter => { name => $vmname } );
	if ( scalar(@$views) ne 1 ) {
		SDK::Error::Entity::NumException->throw( error => 'Entity count not expected', entity => $vmname, count => scalar(@$views) );
	} else {
		return 0;
	}
}

## Functionality test sub
sub test( ) {
	print "Vcenter module test sub\n";
}

#### We need to end with success
1
