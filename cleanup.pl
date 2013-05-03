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
#use VMware::VILib;
#use AppUtil::VMUtil;
use Data::Dumper;
#use Switch;

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
);
Opts::add_options(%opts);
Opts::parse();
Opts::validate();
my $username = Opts::get_option('username');
my $password = Opts::get_option('password');
my $datacenter = Opts::get_option('datacenter');
my $url = Opts::get_option('url');
Util::connect( $url, $username, $password );

my $rp_pools = Vim::find_entity_views( view_type => 'ResourcePool');
my $parent_rp = Vim::find_entity_view( view_type => 'ResourcePool', filter => { name => 's4mur4i' });

foreach my $pool (@$rp_pools) {
	if ( ! defined($pool->resourcePool)) {
		print "No Child resource pools in Resource pool: " . $pool->name . "\n";
		if ( ! defined($pool->vm) ) {
			print "There are no child vm-s: " . $pool->name . "\n";
			my $vim=Vim::get_vim;
			my $path = Util::get_inventory_path( $pool, $vim );
			print "$path\n";
			if ( $path =~ m/^\s*Support\/host\/[^\/]*\/Resources\/[^\/]*\s*$/)  {
				print "Top level Resource pool.. just empty\n";
			} else {
				print "\tSafe to delete Resource pool: " . $pool->name . "\n";
				eval {
					$pool->Destroy_Task;
				};
			if ($@) {
				if (ref($@) eq 'SoapFault') {
					if (ref($@->detail) eq 'RuntimeFault') {
						Util::trace(0, "There was a runtimefault.\n");
					} elsif (ref($@->detail) eq 'VimFault') {
						Util::trace(0,"There was a fault on the Vsphere\n");
					} else {
						Util::trace (0, "Fault" . $@ . ""   );
					}
					exit 1;
				} else {
					Util::trace (0, "Fault" . $@ . ""   );
					exit 1;
				};
			};
			print "\tResource pool deleted: " . $pool->name . "\n";
			}
		} else {
			print "There are child vm-s: ". $pool->name . "\n";
		}
	} else {
		print "Resource pool has child resource pools: ". $pool->name . "\n";
	}
}
# Disconnect from the server
Util::disconnect();
# To mitigate SSL warnings by default
BEGIN {
	$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
}
