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
Util::trace( 0, "===================================================================\n" );
Util::trace( 0, "Machine is provisioned.\n" );
Util::trace( 0, "Login: '" . $Support::template_hash{$os}{'username'} . "' / '" . $Support::template_hash{$os}{'password'} ."'\n" );
Util::trace( 0, "Unique name of vm: " . $vmname . "\n" );
};
if ($@) { &Error::catch_ex( $@ ); }
# Disconnect from the server
Util::disconnect();
# To mitigate SSL warnings by default
BEGIN {
	$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
}
