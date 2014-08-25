#!/usr/bin/perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use SDK::Support;
use VMware::VIRuntime;
use Data::Dumper;

sub createfolder {
	my( $folder, $name ) = @_;
	my $new_folder;
	eval {
		$new_folder = $folder->CreateFolder(name => $name);
		if($new_folder->type eq 'Folder') {
			print "Successfully created new folder: \"" . $name . "\"\n";
		} else {
			print "Error: Unable to create new folder: \"" . $name . "\"\n";
		}
	};
	if($@) {
		print "Error: " . $@ . "\n";
		die "We could not create the folder for the machines.";
	}
	return $new_folder;
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
);
Opts::add_options(%opts);
Opts::parse();
Opts::validate();
my $username = Opts::get_option('username');
my $password = Opts::get_option('password');
my $datacenter = Opts::get_option('datacenter');
my $url = Opts::get_option('url');
Util::connect( $url, $username, $password );
my $machines = Vim::find_entity_views(view_type=>'VirtualMachine');
my $vim = Vim::get_vim;
foreach my $machine_view (@$machines) {
#	print Dumper($machine_view);
	print "Doing machine:" . $machine_view->{'name'} . "\n";
	my $path = Util::get_inventory_path($machine_view, $vim);
	# Support/vm/SCB-xenapp
	$path =~ s/^Support\/vm\///;
	print "My path is: $path\n";
	if ( $path =~ m@^[^\/]*/[^\/]*@) {
		print "Not at top level\n";
		next;
	}
	my $rp = Vim::get_view(mo_ref=> $machine_view->resourcePool);
	my $rp_path = Util::get_inventory_path($rp, $vim);
	#Support/host/vmware-it1.balabit/Resources/s4mur4i/277
	$rp_path =~ s/^[^\/]*\/[^\/]*\/[^\/]*\/[^\/]*\///;
	print "My rp path is : $rp_path\n";
	my @rp_path = split("/", $rp_path);
	my $parent_folder = Vim::get_view(mo_ref=>$machine_view->parent);
	foreach (@rp_path) {
		my $test = Vim::find_entity_view(view_type => 'Folder', begin_entity => $parent_folder, filter => { name => $_ });
#		print Dumper($test);
		if ( defined($test->{'mo_ref'}->{'type'}) ) {
			$parent_folder = $test;
			next;
		} else {
			$parent_folder = createfolder( $parent_folder, $_ );
			print Dumper($parent_folder);
		}
	}
	$parent_folder->MoveIntoFolder( list=>$machine_view);
	print "Moved machine " . $machine_view->{'name'} . "into folder" . $parent_folder->{'name'} . "\n";
}
# Disconnect from the server
Util::disconnect();
# To mitigate SSL warnings by default
BEGIN {
	$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
}
