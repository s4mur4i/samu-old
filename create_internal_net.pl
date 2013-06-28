#!/usr/bin/perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use lib '/usr/lib/vmware-vcli/apps';
use SDK::Support;
use VMware::VICommon;
use VMware::VIRuntime;
use Data::Dumper;

## Add new modul structure
sub get_interface {
        my ($machine_ref) = @_;
        my @keys;
        my @unitnumber;
        my @controllerkey;
        my @mac;
        $machine_ref = Vim::find_entity_view(view_type=>'VirtualMachine', filter=> {name => $machine_ref});
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
	my ($type) = $machine_ref->name =~ m/^[^-]*-[^-]*-([^_]*)_[^-]*-\d{1,3}$/ ;
	if ($type eq 'scb' ) {
		if ( (@keys lt 4) && (@unitnumber lt 4) && (@controllerkey lt 4) ) {
			print "Not enough interfaces.\n";
			exit 1;
		}
		return ($keys[1],$unitnumber[1],$controllerkey[1],$mac[1]);
	} else {
		if ( (@keys lt 1) && (@unitnumber lt 1) && (@controllerkey lt 1) ) {
			print "Not enough interfaces.\n";
			exit 1;
		}
		return ($keys[0],$unitnumber[0],$controllerkey[0],$mac[0]);
	}
}

my %opts = (
	vm => {
		type => "=s",
		help => "List of vms to put in one internal interface. Machines should be comma seperated. Example: test1,test2,test3",
		required => 1,
	},

);
Opts::add_options(%opts);
Opts::parse();
Opts::validate();
my $username = Opts::get_option('username');
my $password = Opts::get_option('password');
my $url = Opts::get_option('url');
Util::connect( $url, $username, $password );
my $vm = Opts::get_option('vm');
my @vm = split(',',$vm);
print "Vms to process: " . Dumper(@vm);
### First machine will be dedicated ticket

my ($ticket,$uniq) = $vm[0] =~ m/^([^-]*)-[^-]*-[^-]*-(\d{3})$/ ;
if ( !defined($ticket)) {
	print "Could not extract information from first machine. name => '$vm[0]'\n";
	exit 1;
}
foreach (@vm) {
	my $vm = Vim::find_entity_view(view_type=>'VirtualMachine', filter=> {name => $_});
	if ( !defined($vm)) {
		print "Machine does not exist => $_ \n";
		exit 2;
	}
}
## See if we need to create internal switch
my $dvs_view = Vim::find_entity_view( view_type => 'DistributedVirtualSwitch', filter => { 'name' => $ticket });
if ( !defined($dvs_view) ) {
	print "Creating Virtual switch\n";
	my $root_folder = Vim::find_entity_view( view_type => 'Folder', filter => {name => 'network'});
	## Configuring the DVS
	my $host_view = Vim::find_entity_view(view_type => 'HostSystem', filter => { name => 'vmware-it1.balabit'});
	my $hostspec = DistributedVirtualSwitchHostMemberConfigSpec->new(operation=>'add', maxProxySwitchPorts=>99,host=>$host_view);
	my $dvsconfigspec = DVSConfigSpec->new(name=>$ticket, maxPorts=>99,description=>"DVS for ticket $ticket",host=>[$hostspec]);
	my $spec = DVSCreateSpec->new(configSpec=>$dvsconfigspec);
	$root_folder->CreateDVS_Task(spec=>$spec);
	while (!defined($dvs_view)) {
		print "Waiting for DVS create task to complete.\n";
		sleep 5;
		$dvs_view = Vim::find_entity_view( view_type => 'DistributedVirtualSwitch', filter => { 'name' => $ticket });
	}
}
my @portgroups = @{$dvs_view->summary->portgroupName};
my $present=1;
my $portgroupname="$ticket-int-$uniq";
foreach (@portgroups) {
	if ( $_ =~ /^$portgroupname/ ) {
		print "There is already a HA interface for these machines.\n";
		$present=0;
		last;
	}
}
if ( $present ) {
	## Create DV port group
	my $spec = DVPortgroupConfigSpec->new(name=>$portgroupname, type=>'earlyBinding',numPorts=>2,description=>"HA interface");
	eval { $dvs_view->AddDVPortgroup_Task(spec=>$spec); };
	if ($@) {
	      if (ref($@) eq 'SoapFault') {
		    if (ref($@->detail) eq 'DuplicateName') {
			  Util::trace(0, "ERR: a portgroup with the same name already exists.\n");
		    }
		    elsif (ref($@->detail) eq 'DvsFault') {
			  Util::trace(0, "ERR: operation fails on any host.\n");
		    }
		    elsif (ref($@->detail) eq 'InvalidName') {
			  Util::trace(0, "ERR: name of the portgroup is invalid.\n");
		    }
		    elsif (ref($@->detail) eq 'RuntimeFault') {
			  Util::trace(0, "ERR: runtime fault.\n");
		    }
		    else {
			  Util::trace(0, "ERR: ". $@ . "\n");
		    }
	      }
	      else {
		   Util::trace(0, "ERR: ". $@ . "\n");
	      }
	      exit(1);
	}
}
my $pg_view = Vim::find_entity_view( view_type => 'DistributedVirtualPortgroup', filter => { 'name' => $portgroupname });
while (!defined($pg_view)) {
	print "Waiting for port group to be available.\n";
	sleep 5;
	$pg_view = Vim::find_entity_view( view_type => 'DistributedVirtualPortgroup', filter => { 'name' => $portgroupname });
}
my $dvs_entity_key = $pg_view->config->distributedVirtualSwitch;
my $dvs_entity = Vim::get_view(mo_ref => $dvs_entity_key);
my $dvs_uuid = $dvs_entity->uuid;
my $portgroup_key = $pg_view->key;
my $port = DistributedVirtualSwitchPortConnection->new(portgroupKey=>$portgroup_key, switchUuid=>$dvs_uuid);
my $backing = VirtualEthernetCardDistributedVirtualPortBackingInfo->new(port=>$port);
my $vdev_connect_info = VirtualDeviceConnectInfo->new( startConnected =>'1', allowGuestControl =>'1', connected => '1');

foreach (@vm) {
	my ($int_key, $int_unitnumber, $int_controllerkey, $int_mac ) = &get_interface($_);
	my $device =  VirtualE1000->new(key=>$int_key,backing=>$backing,controllerKey=>$int_controllerkey,unitNumber=>$int_unitnumber,connectable=>$vdev_connect_info,macAddress=>$int_mac,wakeOnLanEnabled=>1,addressType=>'Manual');
	my $configspec = VirtualDeviceConfigSpec->new(operation=>VirtualDeviceConfigSpecOperation->new('edit'),device=>$device);
	my $spec = VirtualMachineConfigSpec->new(deviceChange=>[$configspec]);
	my $machine_ref = Vim::find_entity_view(view_type=>'VirtualMachine', filter=> {name =>$_});
	eval { $machine_ref->ReconfigVM_Task(spec=>$spec); };
	if ($@) {
		print Dumper($@);
	}
}

# Disconnect from the server
Util::disconnect();
# To mitigate SSL warnings by default
BEGIN {
	$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
}
