#!/usr/bin/perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use SDK::Support;
use SDK::Vcenter;
use SDK::Misc;
use VMware::VIRuntime;
use Data::Dumper;

sub get_config_spec() {
   if (defined(Opts::get_option('memory')) && defined(Opts::get_option('cpu'))) {
	   my $memory = Opts::get_option('memory');  # in MB;
	   my $num_cpus = Opts::get_option('cpu');
	   my $vm_config_spec = VirtualMachineConfigSpec->new( memoryMB => $memory, numCPUs => $num_cpus,deviceChange=>&Support::generate_network_setup_for_clone(Opts::get_option('os_temp')) );
	   return $vm_config_spec;
   } elsif (defined(Opts::get_option('memory'))) {
	my $memory = Opts::get_option('memory');
	my $vm_config_spec = VirtualMachineConfigSpec->new( memoryMB => $memory,deviceChange=>&Support::generate_network_setup_for_clone(Opts::get_option('os_temp')) );
        return $vm_config_spec;
   } elsif (defined(Opts::get_option('cpu'))) {
	my $num_cpus = Opts::get_option('cpu');
	my $vm_config_spec = VirtualMachineConfigSpec->new( numCPUs => $num_cpus,deviceChange=>&Support::generate_network_setup_for_clone(Opts::get_option('os_temp')) );
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
my $vmname = &Misc::generate_vmname($ticket,$username,$os);
my $host_view = Vim::find_entity_view(view_type => 'HostSystem', filter => { name => 'vmware-it1.balabit'});
my $relocate_spec = VirtualMachineRelocateSpec->new( host => $host_view, diskMoveType => "createNewChildDiskBacking", pool => $resource_pool);
#my $fileinfo = VirtualMachineFileInfo->new();
#my $config_spec = VirtualMachineConfigSpec->new( files => $fileinfo);
my $config_spec = &get_config_spec();
my $clone_spec;
if ( $Support::template_hash{$os}{'os'} =~ /win/) {
	$clone_spec = &Support::win_VirtualMachineCloneSpec($os,$snapshot_view,$relocate_spec,$config_spec);
} elsif ($Support::template_hash{$os}{'os'} =~ /lin/) {
	$clone_spec = &Support::lin_VirtualMachineCloneSpec($os,$snapshot_view,$relocate_spec,$config_spec);
} else {
	$clone_spec = &Support::oth_VirtualMachineCloneSpec($os,$snapshot_view,$relocate_spec,$config_spec);
}
my $task = $template_mo_ref->CloneVM_Task(  folder => $dest_folder_view->{'mo_ref'}, name=> $vmname, spec=> $clone_spec);
&Vcenter::Task_getStatus($task);
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
