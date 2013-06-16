#!/usr/bin/perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use lib '/usr/lib/vmware-vcli/apps';
use Support;
use VMware::VICommon;
use VMware::VIRuntime;
use Data::Dumper;

sub get_ha_interface {
	my ($machine_ref) = @_;
	my @keys;
	my @unitnumber;
	my @controllerkey;
	foreach ( @{$machine_ref->config->hardware->device}) {
		my $interface = $_;
		if ( !$interface->isa('VirtualE1000')) {
			next;
		}
		push(@keys,$interface->key);
		push(@unitnumber,$interface->unitNumber);
		push(@controllerkey,$interface->controllerKey);
	}
	if ( (@keys lt 2) && (@unitnumber lt 2) && (@controllerkey lt 2) ) {
		print "Not enough interfaces.\n";
		exit 1;
	}
	return ($keys[1],$unitnumber[1],$controllerkey[1]);
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
my $datacenter = Opts::get_option('datacenter');
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
my ($ha1_int_key, $ha1_int_unitnumber, $ha1_int_controllerkey) = &get_ha_interface($ha1);
my ($ha2_int_key, $ha2_int_unitnumber, $ha2_int_controllerkey ) = &get_ha_interface($ha2);
my $dvs_view = Vim::find_entity_view( view_type => 'DistributedVirtualSwitch', filter => { 'name' => $ticket });
if ( !defined($dvs_view) ) {
	print "Creating Virtual switch\n";
	my $root_folder = Vim::find_entity_view( view_type => 'Folder', filter => {name => 'network'});
	## Configuring the DVS
#	my $dvs_views = Vim::find_entity_view( view_type => 'DistributedVirtualSwitch', filter => { 'name' => "dvSwitch4MVH" });
#	print Dumper($dvs_views);
#	my $view = Vim::get_view(mo_ref=> $dvs_views->parent);
#	print Dumper($view);
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
#my $dvs_views = Vim::find_entity_view( view_type => 'DistributedVirtualSwitch', filter => { 'name' => "dvSwitch4MVH" });
#print Dumper($dvs_view);
my $uuid = $dvs_view->uuid;
my @portgroups = @{$dvs_view->summary->portgroupName};
my $present=1;
foreach (@portgroups) {
	if ( $_ =~ /^$ticket-ha-int-$uniq1-$uniq2/ ) {
		print "There is already a HA interface for these machines.\n";
		$present=0;
		last;
	}
}
if ( $present ) {
	## Create DV port group
	my $spec = DVPortgroupConfigSpec->new(name=>"$ticket-ha-int-$uniq1-$uniq2", type=>'earlyBinding',numPorts=>2,description=>"HA interface");
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
$dvs_view = Vim::find_entity_view( view_type => 'DistributedVirtualPortgroup', filter => { 'name' => "$ticket-ha-int-$uniq1-$uniq2" });
my $portgroup_key = $dvs_view->key;
my $configspec = VirtualDeviceConfigSpecOperation->new('edit');
#my $backing1 = VirtualEthernetCardDistributedVirtualPortBackingInfo->new(portgroupKey=>$portgroup_key, switchUuid=>$uuid);
my $port = DistributedVirtualSwitchPortConnection->new(portgroupKey=>$portgroup_key, switchUuid=>$uuid);
my $backing1 = VirtualEthernetCardDistributedVirtualPortBackingInfo->new(port=>$port);
my $device1 =  VirtualDevice->new(key=>$ha1_int_key,backing=>$backing1,controllerKey=>$ha1_int_controllerkey,unitNumber=>$ha1_int_unitnumber);
my $configspec1 = VirtualDeviceConfigSpec->new(operation=>$configspec, device=>$device1);
my $spec1 = VirtualMachineConfigSpec->new(deviceChange=>[$configspec1]);
#print Dumper($spec1);
eval { $ha1->ReconfigVM_Task(spec=>$spec1); };
if ($@) {
	print Dumper($@);
}


#$ha2
# Disconnect from the server
Util::disconnect();
# To mitigate SSL warnings by default
BEGIN {
	$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
}
