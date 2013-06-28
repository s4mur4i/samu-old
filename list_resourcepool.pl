#!/usr/bin/perl

use strict;
use warnings;
use lib '/usr/lib/vmware-vcli/apps';
use VMware::VIRuntime;
use AppUtil::VMUtil;
use VMware::VILib;
use Data::Dumper;
use Switch;

sub display {
   my %args = @_;
   my $name = $args{name};
   my $value = $args{value};
   Util::trace(0,$name . " " . $value . "\n");
}

sub convert_seconds_to_hhmmss {
	my $dayz=int($_[0]/86400);
	my $leftover=$_[0] % 86400;
	my $hourz=int($leftover/3600);
	$leftover=$leftover % 3600;
	my $minz=int($leftover/60);
	my $secz=int($leftover % 60);
	return sprintf ("%03d:%02d:%02d:%02d", $dayz,$hourz,$minz,$secz)
}

#sub path_dispaly(@) {
## Fixme
#}
## Taken from VMware:

sub get_search_filter_spec {
   my ($class, $moref, $property_spec) = @_;
   my $resourcePoolTraversalSpec =
      TraversalSpec->new(name => 'resourcePoolTraversalSpec',
                         type => 'ResourcePool',
                         path => 'resourcePool',
                         skip => 1,
                         selectSet => [SelectionSpec->new(name => 'resourcePoolTraversalSpec'),
                           SelectionSpec->new(name => 'resourcePoolVmTraversalSpec'),]);

   my $resourcePoolVmTraversalSpec =
      TraversalSpec->new(name => 'resourcePoolVmTraversalSpec',
                         type => 'ResourcePool',
                         path => 'vm',
                         skip => 1);

   my $computeResourceRpTraversalSpec =
      TraversalSpec->new(name => 'computeResourceRpTraversalSpec',
                type => 'ComputeResource',
                path => 'resourcePool',
                skip => 1,
                selectSet => [SelectionSpec->new(name => 'resourcePoolTraversalSpec')]);


   my $computeResourceHostTraversalSpec =
      TraversalSpec->new(name => 'computeResourceHostTraversalSpec',
                         type => 'ComputeResource',
                         path => 'host',
                         skip => 1);

   my $datacenterHostTraversalSpec =
      TraversalSpec->new(name => 'datacenterHostTraversalSpec',
                     type => 'Datacenter',
                     path => 'hostFolder',
                     skip => 1,
                     selectSet => [SelectionSpec->new(name => "folderTraversalSpec")]);

   my $datacenterVmTraversalSpec =
      TraversalSpec->new(name => 'datacenterVmTraversalSpec',
                     type => 'Datacenter',
                     path => 'vmFolder',
                     skip => 1,
                     selectSet => [SelectionSpec->new(name => "folderTraversalSpec")]);

   my $hostVmTraversalSpec =
      TraversalSpec->new(name => 'hostVmTraversalSpec',
                     type => 'HostSystem',
                     path => 'vm',
                     skip => 1,
                     selectSet => [SelectionSpec->new(name => "folderTraversalSpec")]);

   my $folderTraversalSpec =
      TraversalSpec->new(name => 'folderTraversalSpec',
                       type => 'Folder',
                       path => 'childEntity',
                       skip => 1,
                       selectSet => [SelectionSpec->new(name => 'folderTraversalSpec'),
                       SelectionSpec->new(name => 'datacenterHostTraversalSpec'),
                       SelectionSpec->new(name => 'datacenterVmTraversalSpec',),
                       SelectionSpec->new(name => 'computeResourceRpTraversalSpec'),
                       SelectionSpec->new(name => 'computeResourceHostTraversalSpec'),
                       SelectionSpec->new(name => 'hostVmTraversalSpec'),
                       SelectionSpec->new(name => 'resourcePoolVmTraversalSpec'),
                       ]);

   my $obj_spec = ObjectSpec->new(obj => $moref,
                                  skip => 1,
                                  selectSet => [$folderTraversalSpec,
                                                $datacenterVmTraversalSpec,
                                                $datacenterHostTraversalSpec,
                                                ]);
	return PropertyFilterSpec->new(propSet => $property_spec,
                                  objectSet => [$obj_spec]);
}
my %opts = (
	username => {
		type => ":s",
		variable => "VI_USERNAME",
		help => "Username to ESX",
	},
	password => {
		type => ":s",
		variable => "VI_PASSWORD",
		help => "Password to ESX",
	},
	server => {
		type => ":s",
		variable => "VI_SERVER",
		help => "ESX hostname or IP address",
		default => "vcenter.ittest.balabit",
	},
	protocol => {
		type => ":s",
		variable => "VI_PROTOCOL",
		help => "http or https, that is the question",
		default => "https",
	},
	portnumber => {
		type => ":i",
		variable => "VI_PROTOCOL",
		help => "ESX port for connection",
		default => "443",
	},
	url => {
		type => ":s",
		variable => "VI_URL",
		help => "URL for ESX",
	},
	datacenter => {
		type => ":s",
		help => "Datacenter",
		default => "support",
	},
	pool => {
		type => ":s",
		help => "The resource pool we are interested",
	}
);
Opts::add_options(%opts);
Opts::parse();
Opts::validate();
my $username = Opts::get_option('username');
my $password = Opts::get_option('password');
my $datacenter = Opts::get_option('datacenter');
my $url = Opts::get_option('url');
Util::connect( $url, $username, $password );
### Everyone has his own resource pool and schold only try to list items from it.
my $entityname;
if ( defined(Opts::get_option('pool'))) {
	$entityname = Opts::get_option('pool');
} else {
	$entityname = Opts::get_option('username');
}
#print "entityname: $entityname\n";
#$entityname = "test";
my $vim=Vim::get_vim;
my $rp_views = Vim::find_entity_views (view_type => 'ResourcePool', filter => {name => $entityname});
unless (@$rp_views) { Util::trace(0, "Resource pool $entityname not found.\n"); }
foreach(@$rp_views) {
	my $rp = $_;
	my $path= Util::get_inventory_path($_, $vim);
	if ( $path =~ m/^\s*Support\/host\/.*\/Resources\/$entityname\s*$/ ) {
		#my $result = get_entities(view_type => 'VirtualMachine', obj => $rp);
		my $sc = Vim::get_service_content();
		my $service = Vim::get_vim_service();
		my $property_spec = PropertySpec->new(all => 0, type => 'VirtualMachine'->get_backing_type());
		my $property_filter_spec = 'VirtualMachine'->get_search_filter_spec($rp,[$property_spec]);
		my $obj_contents = $service->RetrieveProperties(_this => $sc->propertyCollector, specSet => $property_filter_spec);
		my $result = Util::check_fault($obj_contents);
		foreach (@$result) {
			my $obj_content = $_;
			my $mob = $obj_content->obj;
			my $obj = Vim::get_view(mo_ref=>$mob);
			display(name=>"VM :",value=>$obj->name);
			## Where is the VM
			my $path= Util::get_inventory_path($obj, $vim);
			$path =~ s/^\s*Support\/vm\///;
			my @path = split( '/', $path);
			print "\tInventory Path: Root ";
			foreach my $level (@path) {
				print " -> $level";
			}
			print "\n";
			my $parent_rp_view = Vim::get_view(mo_ref=>$obj->resourcePool);
			my $parent_path= Util::get_inventory_path($parent_rp_view,$vim);
			## Support/host/vmware-it1.balabit/Resources/test/test
			$parent_path =~ s/^\s*Support\/host\/.*\/Resources\///;
			my @parent_path = split( '/', $parent_path);
			print "\tParent resourcepool path: Root ";
			foreach my $parent_level (@parent_path) {
				print " -> $parent_level";
			}
			print "\n";
			my $ip;
			if ( defined($obj-> {'guest'} -> {'ipAddress'})) {
				$ip = $obj-> {'guest'} -> {'ipAddress'};
			} else {
				$ip = "Unknown";
			}
			print "\tIp address of guest: " . $ip ."\n";
			## Vmware tools
			my $tools= $obj->{'guest'}->{'toolsStatus'}->{'val'};
			switch($tools) {
				case "toolsNotInstalled" { $tools = "VMware Tools has never been installed or has not run in the virtual machine." }
				case "toolsNotRunning" { $tools = "VMware Tools is not running." }
				case "toolsOk" { $tools = "VMware Tools is running and the version is current." }
				case "toolsOld" { $tools = "VMware Tools is running, but the version is not current." }
			}
			print "\tVmware Tools: $tools\n";
			## Power State
			my $state = $obj->{'guest'}->{'guestState'};
			switch() {
				case "running" { $state = "Guest is running normally." }
				case "shuttingdown" { $state = "Guest has a pending shutdown command." }
				case "resetting" { $state = "Guest has a pending reset command." }
				case "standby" { $state = "Guest has a pending standby command." }
				case "notrunning" { $state = "Guest is not running." }
				case "unknown" { $state = "Guest information is not available. " }
			}
			print "\tPowerstate: $state\n";
			## Active memory usage in MB
			my $active_memory = $obj ->{'summary'}-> {'quickStats'}->{'guestMemoryUsage'};
			print "\tActive memory usage: $active_memory MB\n";
			## Active Cpu usage in Mhz
			my $active_cpu = $obj ->{'summary'}-> {'quickStats'}->{'overallCpuUsage'};
			print "\tActive cpu usage: $active_cpu Mhz\n";
			## OS type
			my $os;
			if ( defined($obj ->{'guest'}->{'guestFullName'})) {
				$os = $obj ->{'guest'}->{'guestFullName'};
			} else {
				if ( defined($obj ->{'guest'}->{'guestFamily'} )) {
					$os = $obj ->{'guest'}->{'guestFamily'};
				} else {
					$os = "unknown";
				}
			}
			print "\tOS: $os\n";
			## Alert
			my $alert = $obj ->{'summary'}->{'overallStatus'}->{'val'};
			switch($alert) {
				case "gray" { $alert = "The status is unknown." }
				case "green" { $alert = "The entity is OK." }
				case "red" { $alert = "!!! The entity definitely has a problem. !!!" }
				case "yellow" { $alert = "!!! The entity might have a problem. !!!" }
			}
			print "\tAlarm: $alert\n";
			## uptime
			my $uptime;
			if ( defined($obj ->{'summary'}->{'quickStats'}->{'uptimeSeconds'}) ) {
				$uptime = convert_seconds_to_hhmmss($obj ->{'summary'}->{'quickStats'}->{'uptimeSeconds'});
			} else {
				$uptime = "No uptime available.";
			}
			print "\tUptime(ddd:hh:mm:ss): $uptime\n";
		}
	} else {
		print "This is not the resource pool you are looking for.\n";
		my $path= Util::get_inventory_path($_, $vim);
		$path =~ s/^\s*Support\/host\/.*\/Resources\///;
		my @path = split( '/', $path);
		print "Resource Pool path: Root ";
		foreach my $level (@path) {
			print " -> $level";
		}
		print "\n";
	}
}
# Disconnect from the server
Util::disconnect();
# To mitigate SSL warnings by default
BEGIN {
	$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
}
