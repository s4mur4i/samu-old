#!/usr/bin/perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use lib '/usr/lib/vmware-vcli/apps';
use SDK::Support;
use SDK::Vcenter;
use SDK::Misc;
use VMware::VICommon;
use VMware::VIRuntime;
use Data::Dumper;

sub get_config_spec() {
   if (Opts::get_option('customize_vm') eq "yes") {
	   my $memory = Opts::get_option('memory');  # in MB;
	   my $num_cpus = Opts::get_option('cpu');
	   my $vm_config_spec = VirtualMachineConfigSpec->new( memoryMB => $memory, numCPUs => $num_cpus,deviceChange=>&Support::generate_network_setup_for_clone(Opts::get_option('os_temp')) );
	   return $vm_config_spec;
   } else {
	my $vm_config_spec = VirtualMachineConfigSpec->new(deviceChange=>&Support::generate_network_setup_for_clone(Opts::get_option('os_temp')) );
	return $vm_config_spec;
   }
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
		default => 'Resources',
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
my $vim=Vim::get_vim;
my $ticket = Opts::get_option('ticket');
my $os_temp = Opts::get_option('os_temp');
my $parent_pool = Opts::get_option('parent_pool');
if (!&Vcenter::exists_resource_pool($parent_pool)) {
	print "Parent pool does not exist.\n";
	exit 3;
}
&Vcenter::create_resource_pool($ticket,$parent_pool);
my $resource_pool = Vim::find_entity_view(view_type => 'ResourcePool', filter =>{name=>$ticket} );
## Find template to use
my $os = Opts::get_option('os_temp');
my $source_temp;
if ( defined($Support::template_hash{$os})) {
	$source_temp = $Support::template_hash{$os}{'path'};
} else {
	die "No template to $source_temp.\n";
}
my $sc = Vim::get_service_content();
my $searchindex = Vim::get_view( mo_ref => $sc->searchIndex);
my $view = $searchindex->FindByInventoryPath(inventoryPath => $source_temp);
my $template_mo_ref = Vim::get_view( mo_ref => $view);

## Tempalte folder linked to
&Support::linked_clone_template_folder_path(Opts::get_option('os_temp'));
my $dest_folder_view = Vim::find_entity_view(view_type => 'Folder', filter =>{name=>$os} );

## Get snapshot to link to
my $template_view = &Vcenter::path_to_moref($source_temp);
my $snapshot_view = $template_view->snapshot->rootSnapshotList;
if (defined($snapshot_view->[0]->{'childSnapshotList'})) {
	$snapshot_view= &GuestInternal::find_root_snapshot($snapshot_view->[0]->{'childSnapshotList'});
	$snapshot_view = Vim::get_view (mo_ref =>$snapshot_view->[0]->{'snapshot'});
} else {
	$snapshot_view = Vim::get_view (mo_ref =>$snapshot_view->[0]->{'snapshot'});
}
my $template_folder = Vim::find_entity_view(view_type => 'Folder', filter =>{name=>$os_temp} );
my $vmname = &Misc::generate_vmname($ticket,$resource_pool->name,$os);
## Let the cloneing begin
## CustomizationWinOptions for optimising
my $host_view = Vim::find_entity_view(view_type => 'HostSystem', filter => { name => 'vmware-it1.balabit'});
my $relocate_spec = VirtualMachineRelocateSpec->new( host => $host_view, diskMoveType => "createNewChildDiskBacking", pool => $resource_pool);
my $fileinfo = VirtualMachineFileInfo->new();
my $config_spec = VirtualMachineConfigSpec->new( files => $fileinfo);
my $clone_spec = &get_config_spec();
## Create default customization spec
my $customization_spec;
if ( $Support::template_hash{$os}{'os'} =~ /win/) {
	$clone_spec = &Support::win_VirtualMachineCloneSpec($os,$snapshot_view,$relocate_spec,$config_spec);
} elsif ($Support::template_hash{$os}{'os'} =~ /lin/) {
	$clone_spec = &Support::lin_VirtualMachineCloneSpec($os,$snapshot_view,$relocate_spec,$config_spec);
} else {
	$clone_spec = &Support::oth_VirtualMachineCloneSpec($os,$snapshot_view,$relocate_spec,$config_spec);
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
