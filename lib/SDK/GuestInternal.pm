package GuestInternal;

use strict;
use warnings;
use Data::Dumper;

BEGIN {
        use Exporter;
        our @ISA = qw(Exporter);
        our @EXPORT = qw( &test &acquireGuestAuth &get_xcb_ha_interface &get_interface_info );
        our @EXPORT_OK = qw( &test &acquireGuestAuth &get_xcb_ha_interface &get_interface_info );
}

## Acquire Guest authentication information to authenticate through vmware tools
## Parameters:
##  gOpMgr: Vim::get_service_content()->guestOperationsManager
##  vmview: Entity view to vm
##  gu: guest username
##  gp: guest password
## Returns:
##  NamePasswordAuthentication Object for authentication

sub acquireGuestAuth {
        my ($gOpMgr,$vmview,$gu,$gp) = @_;

        my $authMgr = Vim::get_view(mo_ref => $gOpMgr->authManager);
        my $guestAuth = NamePasswordAuthentication->new(username => $gu, password => $gp, interactiveSession => 'false');

        eval {
                print "Validating guest credentials in " . $vmview->name . " ...\n";
                $authMgr->ValidateCredentialsInGuest(vm => $vmview, auth => $guestAuth);
        };
        if($@) {
                die( "Error: " . $@ . "\n");
                print Dumper($@);
        } else {
                print "Succesfully validated guest credentials!\n";
        }

        return $guestAuth;
}

## Runs a command in the guest through vmware tools
## Parameters:
##  vmname: name of vm to run commands in
##  prog: program to run in guest
##  prog_arg: arguments to program to run
##  env: environment variables to pass to program
##  workdir: workdir to start program in
##  guestusername: guest username to authenticate with
##  guestpassword: guest password to authenticate with
## Returns:
##  pid: pid of task started

sub runCommandInGuest {
        my ($vmname, $prog, $prog_arg, $env, $workdir, $guestusername, $guestpassword) = @_;
        print "Variables: prog => " .$prog. " and arg => ".$prog_arg. "\n";
        my $vm_view = Vim::find_entity_view(view_type=>'VirtualMachine',filter=>{name=>$vmname});
        if ( !(defined($guestusername)) || !defined($guestpassword)) {
                if ( $vmname =~ /^[^-]*-[^-]*-[^-]*-\d{3}$/ ) {
                  my ($os) = $vmname =~ m/^[^-]*-[^-]*-([^-]*)-\d{3}$/ ;
                  if ( defined($Support::template_hash{$os})) {
                        $guestusername=$Support::template_hash{$os}{'username'};
                        $guestpassword=$Support::template_hash{$os}{'password'};
                  } else {
                        print "Regex matched an OS, but no template found to it os=> '$os'\n";
                  }
                }
        }
        print "username=> '$guestusername' password=> '$guestpassword' vmname=> '" . defined($vm_view) . "'\n";
        if ( (!defined($guestusername)) || (!defined($guestpassword)) || (!defined($vm_view)) ) {
                die("Cannot run. some paramter failed to be parsed or guessed... or both: username=> '$guestusername' password=> '$guestpassword' vmname=> '" . defined($vm_view) . "'");
        }
        my $guestOpMgr = Vim::get_view(mo_ref => Vim::get_service_content()->guestOperationsManager);
        my $guestCreds = &acquireGuestAuth($guestOpMgr,$vm_view,$guestusername,$guestpassword);
        my $guestProcMan = Vim::get_view(mo_ref => $guestOpMgr->processManager);
        #my $guestProgSpec = GuestProgramSpec->new(workingDirectory=> $workdir, programPath=> $prog, arguments => $prog_arg, envVariables =>[$env]);
        my $guestProgSpec = GuestWindowsProgramSpec->new(programPath=> $prog, arguments => $prog_arg,startMinimized=>1);
        print Dumper($guestProgSpec);
        my $pid;
        eval {
                $pid = $guestProcMan->StartProgramInGuest(vm=>$vm_view, auth=>$guestCreds, spec=>$guestProgSpec);
        };
        if($@) {
                        print Dumper($@);
                        die( "Error: " . $@);
        }
        return $pid;
}

## Returns HA interface information for XCB products
## Parameters:
##  machine_ref: object reference to machine
## Returns:
##  key: device hardware key for identifying in hardware list
##  unitnumber: unitnumber on controller
##  controllerkey: device controller key
##  mac: mac address used reconfigure would override it

sub get_xcb_ha_interface {
        my ($machine_ref) = @_;
        my @keys;
        my @unitnumber;
        my @controllerkey;
        my @mac;
        foreach ( @{$machine_ref->config->hardware->device}) {
                my $interface = $_;
                if ( !$interface->isa('VirtualE1000')) {
                        next;
                }
                push(@keys,$interface->key);
                push(@unitnumber,$interface->unitNumber);
                push(@controllerkey,$interface->controllerKey);
                push(@mac,$interface->macAddress);
        }
        if ( (@keys lt 4) && (@unitnumber lt 4) && (@controllerkey lt 4) ) {
                print "Not enough interfaces.\n";
                exit 1;
        }
        return ($keys[3],$unitnumber[3],$controllerkey[3],$mac[3]);
}

## Returns interface information of requested machine interface
## Parameters:
##  machine_ref: object reference to machine
##  interface: number of interface to return(vcenter side)
## Returns:
##  key: device hardware key for identifying in hardware list
##  unitnumber: unitnumber on controller
##  controllerkey: device controller key
##  mac: mac address used reconfigure would override it

sub get_interface_info {
        my ($machine_ref, $interface) = @_;
        my @keys;
        my @unitnumber;
        my @controllerkey;
        my @mac;
        foreach ( @{$machine_ref->config->hardware->device}) {
                my $interface = $_;
                if ( !$interface->isa('VirtualE1000')) {
                        next;
                }
                push(@keys,$interface->key);
                push(@unitnumber,$interface->unitNumber);
                push(@controllerkey,$interface->controllerKey);
                push(@mac,$interface->macAddress);
        }
	## We need to increment interface count because of perl indexing
	my $increment + $interface +1;
        if ( (@keys lt $increment) && (@unitnumber lt $increment) && (@controllerkey lt $increment) ) {
                print "Not enough interfaces. Interface $interface was requested but only @keys interfaces\n";
                exit 1;
        }
        return ($keys[$interface],$unitnumber[$interface],$controllerkey[$interface],$mac[$interface]);
}


## Functionailty test sub
sub test() {
        print "GuestInternal module test sub\n";
}

#### We need to end with success
1
