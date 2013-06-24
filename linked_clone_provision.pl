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
use Data::Dumper;

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

## Very costly need to optimise.
sub compare_mac {
	my ($mac) = @_;
	### FIXME only use the required objects, no need to query all
	my $vm_view = Vim::find_entity_views(view_type => 'VirtualMachine',properties =>['config.hardware.device','summary.config.name']);

	foreach(@$vm_view) {
		my $vm_name = $_->get_property('summary.config.name');
		my $devices =$_->get_property('config.hardware.device');
		my $mac_string;
		foreach(@$devices) {
			if($_->isa("VirtualEthernetCard")) {
				$mac_string = $_->macAddress;
				if ( $mac eq $mac_string ) {
					return 1;
				}
				#print "$vm_name has mac address of $mac_string, but is not matching the generated one\n";
			}
		}
        }
	return 0;
}

## Precheck to see if template has linked folder, if not we need to create it.
sub check_template_folder {
	my $os = Opts::get_option('os_temp');
	my $path = $Support::template_hash{$os}{'path'};
	$path =~ s/\/T_([^\/]*)$/\/$1/;
	my $sc = Vim::get_service_content();
        my $searchindex = Vim::get_view( mo_ref => $sc->searchIndex);
	my $temp_folder = $searchindex->FindByInventoryPath( _this => $searchindex, inventoryPath => $path);
	if (defined($temp_folder)) {
		print "Linked folder exists.\n";
	} else {
		print "Need to create the linked folder.\n";
		$path =~ s/\/[^\/]*$//;
		my $parent_folder = $searchindex->FindByInventoryPath( _this => $searchindex, inventoryPath => $path);
		$parent_folder = Vim::get_view( mo_ref => $parent_folder);
                eval {
                        my $dest_folder_view = $parent_folder->CreateFolder(name => $os);
                };
                if($@) {
                        print "Error: " . $@ . "\n";
                        die "We could not create the folder for the machines.";
                }

	}
}

sub generate_mac {
	my $username = Opts::get_option('username');
	my $mac_base;
	if ( !defined($Support::agents_hash{$username})) {
		$mac_base = "02:01:00:";
	} else {
		$mac_base = $Support::agents_hash{$username}{'mac'};
	}
	my @chars = ( "A" .. "F", "0" .. "9");
	my $mac = join("", @chars[ map { rand @chars } ( 1 .. 6 ) ]);
	$mac =~ s/(..)/$1:/g;
	chop $mac;
	return "$mac_base$mac";
}

sub get_new_mac {
        my $mac = &generate_mac;
        print "First mac address: $mac\n";
        while ( &compare_mac($mac) ) {
                print "Found duplicate mac, need to regenerate\n";
                $mac = &generate_mac;
                print "First mac address: $mac\n";
        }
	return $mac;
}

### FIXME Need to make an external sub to get count of network interfaces. faster run.
sub nicsetting {
	my $os = Opts::get_option('os_temp');
        my @return;
        if ( defined($Support::template_hash{$os})) {
                my $source_temp = $Support::template_hash{$os}{'path'};
                my $sc = Vim::get_service_content();
                my $searchindex = Vim::get_view( mo_ref => $sc->searchIndex);
                my $template_mo_ref = $searchindex->FindByInventoryPath( _this => $searchindex, inventoryPath => $source_temp);
                $template_mo_ref = Vim::get_view( mo_ref => $template_mo_ref);
                foreach ( @{$template_mo_ref->config->hardware->device}) {
                        if ( !$_->isa('VirtualE1000')) {
                                next;
                        }
			my $ip = CustomizationDhcpIpGenerator->new();
			my $adapter = CustomizationIPSettings->new(dnsDomain=>'support.balabit',dnsServerList=>['10.21.0.23'],gateway=>['10.21.255.254'],subnetMask=>'255.255.0.0', ip=>$ip);
			my $nicsetting = CustomizationAdapterMapping->new(adapter=>$adapter);
			push(@return,$nicsetting);
                }
        }
        return \@return;

}

sub get_config_spec() {
	## FIXME through stupid xml out and make it parameter driven
   if (Opts::get_option('customize_vm') eq "yes") {
	   my $memory = Opts::get_option('memory');  # in MB;
	   my $num_cpus = Opts::get_option('cpu');
	   my $vm_config_spec = VirtualMachineConfigSpec->new( memoryMB => $memory, numCPUs => $num_cpus,deviceChange=>&generate_network );
	   return $vm_config_spec;
   } else {
	my $vm_config_spec = VirtualMachineConfigSpec->new(deviceChange=>&generate_network);
	return $vm_config_spec;
   }
}

sub generate_network {
	my $os = Opts::get_option('os_temp');
	my @return;
	if ( defined($Support::template_hash{$os})) {
		my $source_temp = $Support::template_hash{$os}{'path'};
		my $sc = Vim::get_service_content();
		my $searchindex = Vim::get_view( mo_ref => $sc->searchIndex);
		my $template_mo_ref = $searchindex->FindByInventoryPath( _this => $searchindex, inventoryPath => $source_temp);
		$template_mo_ref = Vim::get_view( mo_ref => $template_mo_ref);
		my @keys;
		foreach ( @{$template_mo_ref->config->hardware->device}) {
			my $interface = $_;
			if ( !$interface->isa('VirtualE1000')) {
				next;
			}
			push(@keys,$interface->key)
		}
		my @mac;
		while ( @mac != @keys ) {
			push(@mac, &get_new_mac);
			## inceremntalas
			for (my $i=1;$i<@keys;$i++) {
				my $last=$mac[-1];
				(my  $mac_hex= $last ) =~ s/://g;
				my ($mac_hi, $mac_lo) = unpack("nN", pack('H*', $mac_hex));
				if ($mac_lo == 0xFFFFFFFF) {
				    $mac_hi = ($mac_hi + 1) & 0xFFFF;
				    $mac_lo = 0;
				} else {
				    ++$mac_lo;
				}
				$mac_hex = sprintf("%04X%08X", $mac_hi, $mac_lo);
				push( @mac, join(':', $mac_hex =~ /../sg));
				print "Next interface mac address is $mac[-1]\n";
				if (&compare_mac($mac[$i])) {
					@mac=();
					$i=@keys;
					print "Used mac address regenerating all interfaces\n";
				}
			}
		}

## Need to see if I can generate vmxnet3...
		for (my $i=0;$i<@keys;$i++) {
			my $ethernetcard=VirtualE1000->new(addressType=>'Manual',macAddress=>$mac[$i],wakeOnLanEnabled=>1,key=>$keys[$i]);
			my $operation = VirtualDeviceConfigSpecOperation->new('edit');
			my $deviceconfigspec= VirtualDeviceConfigSpec->new(device=>$ethernetcard,operation=>$operation);
			push(@return,$deviceconfigspec);
		}
	}
	return \@return;
}

my %opts = (
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
	customize_vm => {
		type => "=s",
		help => "Flag to specify whether or not to customize virtual machine: " . "yes,no,camel",
		required => 0,
		default => 'no',
	},
	parent_pool => {
		type => "=s",
		help => "Parent resource pool. Defaults to users pool.",
		required => 0,
	},
	memory => {
                type => "=s",
                help => "Requested memory in MB",
                required => 0,
        },
	cpu => {
                type => "=s",
                help => "Requested Core count for machine",
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
## Find template to use
my $os = Opts::get_option('os_temp');
my $source_temp;
if ( defined($Support::template_hash{$os})) {
	$source_temp = $Support::template_hash{$os}{'path'};
} else {
	die "No template to $source_temp.";
}
&check_template_folder;
my $sc = Vim::get_service_content();
my $searchindex = Vim::get_view( mo_ref => $sc->searchIndex);
my $virtualDiskManager = Vim::get_view( mo_ref => $sc->virtualDiskManager);
my $template_mo_ref = $searchindex->FindByInventoryPath( _this => $searchindex, inventoryPath => $source_temp);
$template_mo_ref = Vim::get_view( mo_ref => $template_mo_ref);
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
my $datacenter_view = Vim::find_entity_view(view_type=>'Datacenter', filter => { name => 'Support'});
### Lets generate the name of the new vm
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
##
## CustomizationWinOptions for optimising
my $host_view = Vim::find_entity_view(view_type => 'HostSystem', filter => { name => 'vmware-it1.balabit'});
my $relocate_spec = VirtualMachineRelocateSpec->new( host => $host_view, diskMoveType => "createNewChildDiskBacking", pool => $dest_rp_view);
my $fileinfo = VirtualMachineFileInfo->new();
my $config_spec = VirtualMachineConfigSpec->new( files => $fileinfo);
my $clone_spec ;
### Create default customization spec
my $customization_spec;
if ( $Support::template_hash{$os}{'os'} =~ /win/) {
	print "Running Windows Sysprep\n";
	my $globalipsettings = CustomizationGlobalIPSettings->new(dnsServerList=>['10.21.0.23'] , dnsSuffixList=>['support.balabit']);
	my $customoptions = CustomizationWinOptions->new(changeSID=>1, deleteAccounts=>0);
	my $custpass = CustomizationPassword->new(plainText=>1, value=>'titkos');
	my $guiunattend = CustomizationGuiUnattended->new(autoLogon=>1, autoLogonCount=>1,password=>$custpass, timeZone=>'095');
	my $customname = CustomizationPrefixName->new(base=>'winguest');
	my $key=$Support::template_hash{$os}{'key'} ;
	my $userdata = CustomizationUserData->new(productId=>$key ,orgName=>'support' ,fullName=>'admin' ,computerName=>$customname );
	my $identification = CustomizationIdentification->new(domainAdmin=>'Administrator@support.balabit', domainAdminPassword=>$custpass,joinDomain=>'support.balabit.');
	### FIXME Possibility to add further commands for logon
	my $runonce = CustomizationGuiRunOnce->new(commandList=>["w32tm /resync", "cscript c:/windows/system32/slmgr.vbs /skms prod-dev-winsrv.balabit", "cscript c:/windows/system32/slmgr.vbs /ato"]);
	### CustomizationAdapterMapping needs interface list
	## FIXME: dynamicly generate nic list
	my @nicsetting = &nicsetting;
	## Workaround for Win 2000 and 2003 licensing
	my $identity;
	if ( ($os =~ /^win_2003/) || ($os =~ /^win_2000/) ) {
		print "Win 2k/2k3 licensing workaround.\n";
		my $automode = CustomizationLicenseDataMode->new('perSeat');
		my $licenseprintdata = 	CustomizationLicenseFilePrintData->new(autoMode=>$automode);
		$identity = CustomizationSysprep->new(guiRunOnce=> $runonce,guiUnattended=>$guiunattend,identification=>$identification , userData=>$userdata, licenseFilePrintData=>$licenseprintdata );
	} else {
		$identity = CustomizationSysprep->new(guiRunOnce=> $runonce,guiUnattended=>$guiunattend,identification=>$identification , userData=>$userdata );
	}
	$customization_spec = CustomizationSpec->new(globalIPSettings=>$globalipsettings, identity=> $identity, options=> $customoptions, nicSettingMap=>@nicsetting);
	$config_spec = get_config_spec();
	$clone_spec = VirtualMachineCloneSpec->new(powerOn => 1,template => 0, snapshot => $snapshot_view, location => $relocate_spec, config => $config_spec, customization => $customization_spec);
} elsif ($Support::template_hash{$os}{'os'} =~ /lin/) {
	print "Running Linux Sysprep\n";
	my @nicsetting = &nicsetting;
	my $hostname = CustomizationPrefixName->new(base=>'linuxguest');
	my $globalipsettings = CustomizationGlobalIPSettings->new(dnsServerList=>['10.21.0.23'] , dnsSuffixList=>['support.balabit']);
	my $linuxprep = CustomizationLinuxPrep->new(domain=>'support.balabit',hostName=>$hostname,timeZone=>'Europe/Budapest',hwClockUTC=>1);
	$customization_spec = CustomizationSpec->new(identity=>$linuxprep, globalIPSettings=> $globalipsettings, nicSettingMap=>@nicsetting);
	$config_spec = get_config_spec();
	$clone_spec = VirtualMachineCloneSpec->new(powerOn => 1,template => 0, snapshot => $snapshot_view, location => $relocate_spec, config => $config_spec, customization => $customization_spec);
} else {
	$config_spec = get_config_spec();
	$clone_spec = VirtualMachineCloneSpec->new(powerOn => 1,template => 0, snapshot => $snapshot_view, location => $relocate_spec,config => $config_spec);
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
			Util::trace (0, "Fault" . $@ . "\n"   );
			print Dumper($@);
		}
		exit 1;
	} else {
		Util::trace (0, "Fault" . $@ . "\n"   );
			print Dumper($@);
		exit 1;
	}
}
print "===================================================================\n";
print "Machine is provisioned.\n";
print "Login: '" . $Support::template_hash{$os}{'username'} . "' / '" . $Support::template_hash{$os}{'password'} ."'\n";
print "Unique name of vm: " . $vmname . "\n";
# Disconnect from the server
Util::disconnect();
# To mitigate SSL warnings by default
BEGIN {
	$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
}
