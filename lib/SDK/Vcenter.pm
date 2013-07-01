package Vcenter;

use strict;
use warnings;
use Data::Dumper;

BEGIN {
        use Exporter;
        our @ISA = qw(Exporter);
        our @EXPORT = qw( &test &mac_compare &Task_getStatus &delete_virtualmachine &check_if_empty_resource_pool &delete_resource_pool );
        our @EXPORT_OK = qw( &test &mac_compare &Task_getStatus &delete_virtualmachine &check_if_empty_resource_pool &delete_resource_pool );
}

## Searches all virtual machines mac address if mac address is already used
## Parameters:
##  mac: mac address to search format: xx:xx:xx:xx:xx:xx
## Returns:
##  true or false according to success

sub mac_compare {
        my ($mac) = @_;
        my $vm_view = Vim::find_entity_views(view_type => 'VirtualMachine',properties =>['config.hardware.device','summary.config.name']);

        foreach(@$vm_view) {
                my $vm_name = $_->get_property('summary.config.name');
                my $devices =$_->get_property('config.hardware.device');
                foreach(@$devices) {
                        if($_->isa("VirtualEthernetCard")) {
                                if ( $mac eq $_->macAddress ) {
                                        return 1;
                                }
                        }
                }
        }
        return 0;
}

sub delete_virtualmachine {
        my ($name) = @_;
        $name = Vim::find_entity_view( view_type => 'VirtualMachine',filter => { name => $name});
        my $powerstate = $name->runtime->powerState->val;
        if ( $powerstate eq 'poweredOn') {
                print "Powering off VM.\n";
                my $task = $name->PowerOffVM;
		&Task_getStatus($task);
        }
	my $task = $name->Destroy_Task;
        &Task_getStatus($task);
        print "Vm deleted succsfully: " . $name->name . "\n";

}

sub Task_getStatus {
        my ($taskRef) = @_;
        my $task_view = Vim::get_view(mo_ref => $taskRef);
        my $taskinfo = $task_view->info->state->val;
        my $continue = 1;
        while ($continue) {
                my $info = $task_view->info;
                if ($info->state->val eq 'success') {
                        $continue = 0;
                } elsif ($info->state->val eq 'error') {
                        my $soap_fault = SoapFault->new;
                        $soap_fault->name($info->error->fault);
                        $soap_fault->detail($info->error->fault);
                        $soap_fault->fault_string($info->error->localizedMessage);
                        die "$soap_fault\n";
                }
                sleep 1;
                $task_view->ViewBase::update_view_data();
        }
}

sub check_if_empty_switch {
	my ($name) = @_;
        $name = Vim::find_entity_view( view_type => 'DistributedVirtualSwitch', filter=> {name=> $name});
	if ( !defined($name)) {
                print "No such switch.\n";
                return 0;
        }
        my $count = $name->summary->portgroupName;
        if (@$count < 2 ) {
		return 1;
	} else {
		return 0;
	}
}

sub check_if_empty_resource_pool {
	my ($name) = @_;
	$name = Vim::find_entity_view( view_type => 'ResourcePool', filter=> {name=> $name});
	if ( !defined($name)) {
		print "No such resource pool.\n";
		return 0;
	}
	if ( defined($name->vm)) {
		return 0;
	} else {
		if (defined($name->resourcePool)) {
			return 0;
		} else {
			return 1;
		}
	}
}

sub check_if_empty_folder {
	my ($name) = @_;
	$name = Vim::find_entity_view( view_type => 'Folder', filter=>{name=>$name});
	if ( !defined($name)) {
                print "No such folder.\n";
                return 0;
        }
	if (!defined($name->childEntity)) {
		return 1;
	} else {
		return 0;
	}
}



sub delete_folder {
	my ($name) = @_;
	if (&check_if_empty_folder($name)) {
		$name = Vim::find_entity_view( view_type => 'Folder', filter=>{name=>$name});
		my $task = $name->Destroy_Task;
                &Task_getStatus($task);
	}
}

sub delete_resource_pool {
	my ($name) = @_;
	if (&check_if_empty_resource_pool($name)) {
		$name = Vim::find_entity_view( view_type => 'ResourcePool', filter=> {name=> $name});
		my $task = $name->Destroy_Task;
		&Task_getStatus($task);
	}
}

## Functionality test sub
sub test() {
        print "Vcenter module test sub\n";
}

#### We need to end with success
1
