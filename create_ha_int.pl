#!/usr/bin/perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use SDK::Support;
use VMware::VICommon;
use VMware::VIRuntime;
use Data::Dumper;

sub get_ha_interface {
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

my %opts = (
	ha1 => {
		type => "=s",
		help => "Ha node 1",
		required => 1,
	},
	ha2 => {
		type => "=s",
		help => "HA node 2",
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
my $ha1 = Opts::get_option('ha1');
my ($ticket,$uniq1) = $ha1 =~ m/^([^-]*)-[^-]*-[^-]*-(\d{3})$/ ;
my $ha2 = Opts::get_option('ha2');
my ($uniq2) = $ha2 =~ m/^[^-]*-[^-]*-[^-]*-(\d{3})$/ ;
$ha1 = Vim::find_entity_view(view_type=>'VirtualMachine', filter=> {name => $ha1});
$ha2 = Vim::find_entity_view(view_type=>'VirtualMachine', filter=> {name => $ha2});
if (!defined($ha1) and !defined($ha2) ) {
	die "ha1 and ha2 cannot be found.";
}
my ($ha1_int_key, $ha1_int_unitnumber, $ha1_int_controllerkey, $ha1_int_mac ) = &get_ha_interface($ha1);
my ($ha2_int_key, $ha2_int_unitnumber, $ha2_int_controllerkey, $ha2_int_mac ) = &get_ha_interface($ha2);
my $dvs_view = Vim::find_entity_view( view_type => 'DistributedVirtualSwitch', filter => { 'name' => $ticket });
if ( !defined($dvs_view) ) {
	print "Creating Virtual switch\n";
	my $root_folder = Vim::find_entity_view( view_type => 'Folder', filter => {name => 'network'});
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
my $portgroupname="$ticket-ha-int-$uniq1-$uniq2";
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
my $device1 =  VirtualE1000->new(key=>$ha1_int_key,backing=>$backing,controllerKey=>$ha1_int_controllerkey,unitNumber=>$ha1_int_unitnumber,connectable=>$vdev_connect_info,macAddress=>$ha1_int_mac,wakeOnLanEnabled=>1,addressType=>'Manual');
my $configspec1 = VirtualDeviceConfigSpec->new(operation=>VirtualDeviceConfigSpecOperation->new('edit'),device=>$device1);
my $spec1 = VirtualMachineConfigSpec->new(deviceChange=>[$configspec1]);
eval { $ha1->ReconfigVM_Task(spec=>$spec1); };
if ($@) {
	print Dumper($@);
}
#FIXME I am really dirty please fix me..
$ha1->ResetVM_Task;
my $device2 =  VirtualE1000->new(key=>$ha2_int_key,backing=>$backing,controllerKey=>$ha2_int_controllerkey,unitNumber=>$ha2_int_unitnumber,connectable=>$vdev_connect_info,,macAddress=>$ha2_int_mac,wakeOnLanEnabled=>1,addressType=>'Manual');
my $configspec2 = VirtualDeviceConfigSpec->new(operation=>VirtualDeviceConfigSpecOperation->new('edit'),device=>$device2);
my $spec2 = VirtualMachineConfigSpec->new(deviceChange=>[$configspec2]);
eval { $ha2->ReconfigVM_Task(spec=>$spec2); };
if ($@) {
        print Dumper($@);
}
#FIXME I am really dirty please fix me..
$ha2->ResetVM_Task;
# Disconnect from the server
Util::disconnect();
# To mitigate SSL warnings by default
BEGIN {
	$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
}
