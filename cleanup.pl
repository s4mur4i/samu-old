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

my %opts = (
);
Opts::add_options(%opts);
Opts::parse();
Opts::validate();
my $username = Opts::get_option('username');
my $password = Opts::get_option('password');
my $url = Opts::get_option('url');
Util::connect( $url, $username, $password );

my $rp_pools = Vim::find_entity_views( view_type => 'ResourcePool');

foreach my $pool (@$rp_pools) {
	if ( ! defined($pool->resourcePool)) {
		if ( ! defined($pool->vm) ) {
			my $vim=Vim::get_vim;
			my $path = Util::get_inventory_path( $pool, $vim );
			if ( $path =~ m/^\s*Support\/host\/[^\/]*\/Resources\/[^\/]*\s*$/)  {
				print "Top level Resource pool.. just empty: " . $pool->name . "\n";
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

my $folders = Vim::find_entity_views( view_type => 'Folder');
foreach my $folder (@$folders) {
	if (!defined($folder->parent) || $folder->parent->type eq 'Datacenter') {
		print "Top level object. No touchy toucy:'" . $folder->name . "'\n";
		next;
	}
	if (!defined($folder->childEntity)) {
		print "No child entities. Deleting folder:'" .$folder->name . "'\n";
		eval {
				$folder->Destroy_Task;
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

		}
	}
}

# Disconnect from the server
Util::disconnect();
# To mitigate SSL warnings by default
BEGIN {
	$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
}
