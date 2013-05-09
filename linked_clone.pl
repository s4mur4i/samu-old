#!/usr/bin/perl

use strict;
use warnings;
#use diagnostics;
use FindBin;
use lib "$FindBin::Bin/lib";
use lib '/usr/lib/vmware-vcli/apps';
use Support;
use VMware::VICommon;
use VMware::VIRuntime;
#use VMware::VILib;
#use AppUtil::VMUtil;
use Data::Dumper;
#use Switch;

sub random {
	my $random;
	$random = int(rand(999));
	return $random;
}

sub find_root_snapshot {
	my ($snapshot) = @_;
	if ( defined($snapshot->[0]->{'childSnapshotList'})) {
		find_root_snapshot($snapshot->[0]->{'childSnapshotList'});
	} else {
		return $snapshot;
	}
}

#Gets the config_spec for customizing the memory, number of cpu's
# and returns the spec
###Fix me... need to parse better and more controlled.
sub get_config_spec() {

   my $parser = XML::LibXML->new();
   my $tree = $parser->parse_file(Opts::get_option('filename'));
   my $root = $tree->getDocumentElement;
   my @cspec = $root->findnodes('Virtual-Machine-Spec');
   my $vmhost  ;
   my $guestid;
   my $datastore;
   my $disksize = 4096;  # in KB;
   my $memory = 256;  # in MB;
   my $num_cpus = 1;
   my $nic_network;
   my $nic_poweron = 1;

   foreach (@cspec) {

      if ($_->findvalue('Memory')) {
         $memory = $_->findvalue('Memory');
      }
      if ($_->findvalue('Number-of-CPUS')) {
         $num_cpus = $_->findvalue('Number-of-CPUS');
      }
   }

   my $vm_config_spec = VirtualMachineConfigSpec->new(
                                                  memoryMB => $memory,
                                                  numCPUs => $num_cpus );
   return $vm_config_spec;
}
my %opts = (
	username => {
		type => "=s",
		variable => "VI_USERNAME",
		help => "Username to ESX",
		required => 0,
	},
	password => {
		type => "=s",
		variable => "VI_PASSWORD",
		help => "Password to ESX",
		required => 0,
	},
	server => {
		type => "=s",
		variable => "VI_SERVER",
		help => "ESX hostname or IP address",
		default => "vcenter.ittest.balabit",
		required => 0,
	},
	protocol => {
		type => "=s",
		variable => "VI_PROTOCOL",
		help => "http or https, that is the question",
		default => "https",
		required => 0,
	},
	portnumber => {
		type => "=i",
		variable => "VI_PROTOCOL",
		help => "ESX port for connection",
		default => "443",
		required => 0,
	},
	url => {
		type => "=s",
		variable => "VI_URL",
		help => "URL for ESX",
		required => 0,
	},
	datacenter => {
		type => "=s",
		help => "Datacenter",
		default => "support",
		required => 0,
	},
	ticket => {
		type => "=s",
		help => "The ticket id the machine is going to be created for",
		required => 1,
	},
	os_temp => {
		type => "=s",
		help => "The machine tempalte we want to use",
		required => 1,
	},
	vmname_destination => {
		type => "=s",
		help => "The name of the target virtual machine",
		required => 0,
	},
	filename => {
		type => "=s",
		help => "The name of the configuration specification file",
		required => 0,
		default => "../sampledata/vmclone.xml",
	},
	customize_guest => {
		type => "=s",
		help => "Flag to specify whether or not to customize guest: yes,no,camel",
		required => 0,
		default => 'no',
	},
	customize_vm => {
		type => "=s",
		help => "Flag to specify whether or not to customize virtual machine: " . "yes,no,camel",
		required => 0,
		default => 'no',
	},
	schema => {
		type => "=s",
		help => "The name of the schema file",
		required => 0,
		default => "../schema/vmclone.xsd",
	},
	snapname => {
		type => "=s",
		help => "Name of Snapshot from pristine base image",
		required => 0,
	},
	parent_pool => {
		type => "=s",
		help => "Parent resource pool. Defaults to users pool.",
		required => 0,
	},
);
Opts::add_options(%opts);
Opts::parse();
Opts::validate();
my $username = Opts::get_option('username');
my $password = Opts::get_option('password');
my $datacenter = Opts::get_option('datacenter');
my $url = Opts::get_option('url');
Util::connect( $url, $username, $password );
my $parent_pool;
my $parent_folder;
my $vim=Vim::get_vim;
if ( Opts::option_is_set('parent_pool')) {
	$parent_pool = Opts::get_option('parent_pool');
} else {
	## Default to our personal resource pool
	$parent_pool = Opts::get_option('username');
}
## Find our root resource pool view
my $parent_pool_views = Vim::find_entity_views(view_type => 'ResourcePool', filter=>{ name => $parent_pool});
my $parent_folder_views = Vim::find_entity_views(view_type => 'Folder', filter=>{ name=> $parent_pool});
foreach (@$parent_pool_views) {
	my $parent_pool_view = $_;
	my $parent_rp_path = Util::get_inventory_path($parent_pool_view, $vim );
	if ( $parent_rp_path =~ m/^\s*Support\/host\/[^\/]*\/Resources\/[^\/]*\s*$/) {
		$parent_pool = $parent_pool_view;
		last;
	} else {
		## Debug information to find duplicate resource pools
		print "Found resource pool with same name on ESX: " . $parent_pool_view->name . "\n";
	}
	if ( \$_ == \@$parent_pool_views[-1]) {
		## Some information if we didn't find any relevant resource pools with name
		print "Last element in pool array\n";
		die "The parent resource pool cannot be found. Call support for help: 0118 999 881 999 119 725 3";
	}
}
## The parent_pool is referenced to a view and should be used since all information is accessible through the view
## Search if we need to create the resource pool
## Ticket number is going to be the name of the resource pool for the machines
my $ticket = Opts::get_option('ticket');
my $dest_rp_view = Vim::find_entity_views(view_type => 'ResourcePool', begin_entity => $parent_pool, filter => { name => $ticket });
if ( @$dest_rp_view) {
	# We have found a resource pool in parent
	print "Resource pool already exists.\n";
	$dest_rp_view = $dest_rp_view->[0];
} else {
	print "We need to create resource pool for ticket.\n";
	## Test if creation was succesful
	eval {
		my $shareslevel= SharesLevel->new('normal');
		my $cpushares = SharesInfo->new(shares => 4000 ,level => $shareslevel);
		my $memshares = SharesInfo->new(shares => 32928,level => $shareslevel);
		my $cpuallocation = ResourceAllocationInfo->new(expandableReservation => 'true', limit => -1, reservation => 0, shares => $cpushares);
		my $memoryallocation = ResourceAllocationInfo->new(expandableReservation => 'true', limit => -1, reservation => 0, shares => $memshares);
		my $rp_spec = ResourceConfigSpec->new(cpuAllocation => $cpuallocation, memoryAllocation => $memoryallocation);
		$dest_rp_view = $parent_pool->CreateResourcePool(name => $ticket, spec => $rp_spec);
		if($dest_rp_view->type eq 'ResourcePool') {
			print "Successfully created new ResourcePool: \"" . $ticket . "\"\n";
		} else {
			print "Error: Unable to create new ResourcePool: \"" . $ticket . "\"\n";
		}
	};
	if($@) {
		print "Error: " . $@ . "\n";
		die "We could not create the resource pool for the machines.";
	}
}

#print Dumper($dest_folder_view->[0]);
#$dest_folder_view = Vim::get_view( mo_ref => $dest_folder_view->[0]->{'mo_ref'});
## Find template to use
my $os = Opts::get_option('os_temp');
my $source_temp;
if ( defined($Support::template_hash{$os})) {
	$source_temp = $Support::template_hash{$os};
} else {
	die "No template to $source_temp.";
}
my $sc = Vim::get_service_content();
my $searchindex = Vim::get_view( mo_ref => $sc->searchIndex);
my $virtualDiskManager = Vim::get_view( mo_ref => $sc->virtualDiskManager);
my $template_mo_ref = $searchindex->FindByInventoryPath( _this => $searchindex, inventoryPath => $source_temp);
$template_mo_ref = Vim::get_view( mo_ref => $template_mo_ref);
#my $template_view = Vim::find_entity_view(view_type=>'VirtualMachine', begin_entity=>$template_mo_ref->parent, filter => { name => $template_mo_ref->name} );
### We need to find our last snapshot to link to
my $snapshot_view = $template_mo_ref->snapshot->rootSnapshotList;
if (defined($snapshot_view->[0]->{'childSnapshotList'})) {
	$snapshot_view = find_root_snapshot( $snapshot_view->[0]->{'childSnapshotList'} );
}
$snapshot_view = Vim::get_view (mo_ref =>$snapshot_view->[0]->{'snapshot'});

my $path = Util::get_inventory_path( Vim::get_view( mo_ref => $template_mo_ref->parent), $vim);
$path = $path . "/" . "$os";
my $temp_folder = $searchindex->FindByInventoryPath( _this => $searchindex, inventoryPath => $path);
## Lets see if we can find inventory folder for us
my $dest_folder_view;
if (defined($temp_folder)) {
	print "Creating folder in linked directory.\n";
	$temp_folder = Vim::get_view( mo_ref => $temp_folder);
	$dest_folder_view = $temp_folder;
} else {
	print "Creating Fallback folder.\n";
	## Create inventory folder aswell to keep both views synced
	foreach (@$parent_folder_views) {
		my $parent_folder_view = $_;
		my $parent_folder_path = Util::get_inventory_path($parent_folder_view, $vim );
		#print "$parent_folder_path\n";
		if ( $parent_folder_path =~ m/^\s*Support\/vm\/[^\/]*\s*$/) {
			$parent_folder = $parent_folder_view;
			last;
		} else {
			## Debug information to find duplicate folder
			print "Found folder with same name on ESX not in root: " . $parent_folder_view->name . "\n";
		}
		if ( \$_ == \@$parent_folder_views[-1]) {
			## Some information if we didn't find any relevant folder with name
			print "Last element in folder array\n";
			die "The parent folder cannot be found. Call support for help: 0118 999 881 999 119 725 3";
		}
	}
	$dest_folder_view = Vim::find_entity_views(view_type => 'Folder', begin_entity => $parent_folder, filter => { name => $ticket });
	if ( @$dest_folder_view) {
		# We have found a folder in parent
		print "Folder already exists.\n";
		$dest_folder_view = $_;
	} else {
		print "We need to create folder for ticket.\n";
		## Test if creation was succesful
		eval {
			$dest_folder_view = $parent_folder->CreateFolder(name => $ticket);
			if($dest_folder_view->type eq 'Folder') {
				print "Successfully created new folder: \"" . $ticket . "\"\n";
			} else {
				print "Error: Unable to create new folder: \"" . $ticket . "\"\n";
			}
		};
		if($@) {
			print "Error: " . $@ . "\n";
			die "We could not create the folder for the machines.";
		}

	}
}

#print Dumper($snapshot_view);
## Create Datastore folder for machine
#my $datastore = Vim::get_view( mo_ref => $template_mo_ref->{'datastore'}->[0]);
#my $filemanager = Vim::get_view( mo_ref => $sc->fileManager );
#my $datastorebrowser = Vim::get_view( mo_ref => $datastore->browser);
## Also create parent folders
#my $datastore_path = "[" . $datastore->{'name'} . "]" . $parent_pool->name . "/" . $ticket;
my $datacenter_view = Vim::find_entity_view(view_type=>'Datacenter', filter => { name => 'Support'});
## Check if directory exists
#my $folder = FileQueryFlags->new(fileSize => 0, fileType => 1, modification => 0, fileOwner => 0);
#my $hostdb_search_spec = HostDatastoreBrowserSearchSpec->new( details => $folder);
#eval {
#	my $browse_task = $datastorebrowser->SearchDatastoreSubFolders(datastorePath=>$datastore_path, searchSpec=>$hostdb_search_spec);
#};
#if ( ref($@) eq 'SoapFault' ) {
#	print "Folder on datastore doesn't exist. Creating.\n";
#	$filemanager->MakeDirectory( _this=> $filemanager, name=> $datastore_path , createParentDirectories=> 'true', datacenter=>$datacenter_view );
#} else {
#	print "Folder already exists on datastore\n";
#};
### Lets generate the name of the new vm
## Fixme need to see if name is unique
my $exit = 1;
my $vmname;
do {
	$vmname = "";
	$vmname = $ticket . "-" . $parent_pool->name . "-" . Opts::get_option('os_temp') . "-" . &random();
	my $temp_view =  Vim::find_entity_view(view_type => 'VirtualMachine', properties=>['name'] , filter => { name => $vmname} );
	if ( ! defined($temp_view->{'name'})) {
		print "Machine name will be : $vmname\n";
		$exit = 0;
	} else {
		print "Name not unique: '$vmname'. Generating a new one.\n";
	}
} while ($exit);
### Let the cloneing begin
#$datastore_path = $datastore_path . "/" .  $vmname;
my $host_view = Vim::find_entity_view(view_type => 'HostSystem', filter => { name => 'vmware-it1.balabit'});
my $relocate_spec = VirtualMachineRelocateSpec->new( host => $host_view, diskMoveType => "createNewChildDiskBacking", pool => $dest_rp_view);
my $fileinfo = VirtualMachineFileInfo->new();
my $config_spec = VirtualMachineConfigSpec->new( files => $fileinfo);
my $clone_spec ;
my $customization_spec;
if ((Opts::get_option('customize_vm') eq "yes") && (Opts::get_option('customize_guest') ne "yes")) {
	$config_spec = get_config_spec();
	$clone_spec = VirtualMachineCloneSpec->new(powerOn => 0,template => 0, snapshot => $snapshot_view, location => $relocate_spec, config => $config_spec,);
} elsif ((Opts::get_option('customize_guest') eq "yes") && (Opts::get_option('customize_vm') ne "yes")) {
	$customization_spec = VMUtils::get_customization_spec (Opts::get_option('filename'));
	$clone_spec = VirtualMachineCloneSpec->new( powerOn => 0, template => 0, snapshot => $snapshot_view, location => $relocate_spec, customization => $customization_spec,);
} elsif ((Opts::get_option('customize_guest') eq "yes") && (Opts::get_option('customize_vm') eq "yes")) {
	$customization_spec = VMUtils::get_customization_spec (Opts::get_option('filename'));
	$config_spec = get_config_spec();
	$clone_spec = VirtualMachineCloneSpec->new( powerOn => 0, template => 0, snapshot => $snapshot_view, location => $relocate_spec, customization => $customization_spec, config => $config_spec,);
} else {
#	$clone_spec = VirtualMachineCloneSpec->new( powerOn => 0, template => 0, snapshot => $snapshot_view, location => $relocate_spec, config => $config_spec);
	$clone_spec = VirtualMachineCloneSpec->new( powerOn => 0, template => 0, snapshot => $snapshot_view, location => $relocate_spec);
}

eval {
	$template_mo_ref->CloneVM(  folder => $dest_folder_view->{'mo_ref'}, name=> $vmname, spec=> $clone_spec);
};

if ($@) {
	if (ref($@) eq 'SoapFault') {
		if (ref($@->detail) eq 'FileFault') {
			Util::trace(0, "\nFailed to access the virtual " ." machine files\n");
		} elsif (ref($@->detail) eq 'InvalidState') {
			Util::trace(0,"The operation is not allowed " ."in the current state.\n");
		} elsif (ref($@->detail) eq 'NotSupported') {
			Util::trace(0," Operation is not supported by the " ."current agent \n");
		} elsif (ref($@->detail) eq 'VmConfigFault') {
			Util::trace(0, "Virtual machine is not compatible with the destination host.\n");
		} elsif (ref($@->detail) eq 'InvalidPowerState') {
			Util::trace(0, "The attempted operation cannot be performed " ."in the current state.\n");
		} elsif (ref($@->detail) eq 'DuplicateName') {
			Util::trace(0, "The name '$vmname' already exists\n");
		} elsif (ref($@->detail) eq 'NoDisksToCustomize') {
			Util::trace(0, "\nThe virtual machine has no virtual disks that" . " are suitable for customization or no guest" . " is present on given virtual machine" . "\n");
		} elsif (ref($@->detail) eq 'HostNotConnected') {
			Util::trace(0, "\nUnable to communicate with the remote host, " ."since it is disconnected" . "\n");
		} elsif (ref($@->detail) eq 'UncustomizableGuest') {
			Util::trace(0, "\nCustomization is not supported " ."for the guest operating system" . "\n");
		} else {
			Util::trace (0, "Fault" . $@ . ""   );
		}
		exit 1;
	} else {
		Util::trace (0, "Fault" . $@ . ""   );
		exit 1;
	}
}

#my $clone = Vim::find_entity_view(view_type => 'VirtualMachine', properties => ['layout.disk'] , filter => { name => $vmname});
#my $disk = $clone->get_property('layout.disk');
#outer: foreach my $vdisk (@$disk) {
#	foreach my $diskfile ( @{$vdisk->{'diskFile'}}) {
#		if ( $diskfile =~ /$vmname/ ) {
#			$disk = $diskfile;
#			last outer;
#		}
#	}
#}
#print "My disk is: '$disk'\n";
#$datastore_path = $datastore_path . "/" .  $vmname;
### Since the Datastore path cannot be changed during clone, we need to move the disk now
#eval {
#	$virtualDiskManager->MoveVirtualDisk_Task( sourceName => $disk , sourceDatacenter => $datacenter_view , destDatacenter => $datacenter_view, destName => $datastore_path, force => 1);
#};
#
#if ($@) {
#	if ( ref($@) eq 'SoapFault') {
#		if (ref($@->detail) eq 'FileFault') {
#			Util::trace(0, "\nFailed to access the virtual " ." machine files\n");
#		} elsif (ref($@->detail) eq 'RuntimeFault') {
#			Util::trace(0, "\nRuntime Fault " ." ohhh no...\n");
#		} else {
#			Util::trace (0, "Fault" . $@ . ""   );
#		}
#	}
#}

# Disconnect from the server
Util::disconnect();
# To mitigate SSL warnings by default
BEGIN {
	$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
}
