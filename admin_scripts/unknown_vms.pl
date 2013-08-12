#!/usr/bin/perl

use strict;
use warnings;
#use diagnostics;
use FindBin;
use lib "$FindBin::Bin/lib";
use lib '/usr/lib/vmware-vcli/apps';
use SDK::Support;
use VMware::VICommon;
use VMware::VIRuntime;
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

my $datacenters = Vim::find_entity_views(view_type => 'Datacenter');
foreach my $datacenter (@$datacenters) {
#	print Dumper($datacenter);
	my @ds_array = ();
		if(defined $datacenter->datastore) {
			@ds_array = (@ds_array, @{$datacenter->datastore});
		}
	my $datastores = Vim::get_views( mo_ref_array => \@ds_array);
#	print "Datastores" . Dumper($datastores);
	for my $datastore (@$datastores) {
#		print "datastore info: " . Dumper($datastore);
		my $datastore_browser = Vim::get_view( mo_ref => $datastore->{'browser'});
#		print "Got ref\n";
			if( ($datastore->host->[0]->mountInfo->accessible) && ($datastore->host->[0]->mountInfo->accessMode eq "readWrite") ) {
			my $path = '[' . $datastore->summary->name . ']';
			print "Datastore: $path \n";
			my $browse_task = $datastore_browser->SearchDatastoreSubFolders(datastorePath=> $path);
#			print  "Browser: " . Dumper($browse_task);
			folder: foreach my $folder (@$browse_task) {
#				print Dumper($folder);
				$folder = $folder->folderPath;
				#if ( $folder !~ m/^\[[^\]]*]\s*\..*$/ || $folder !~  m/^\[[^\]]*]\s*$/ ) {
				if ( $folder !~ /^\[[^\]]*]\s*\./)  {
				#	print "My folderpath is: '$folder'\n";
#					if ( $folder =~ /^\[[^\]]*]\s*[^\/]*\/[^\/]*/) {
#						print "Not subfolder\n";
#						next folder;
#					};
					my ($name) = $folder =~ m/^\[[^\]]*\]\s*([^\/]*)\//;
				#	print "my name is $name\n";
					if ( ! defined($name)) {
						next folder;
					};
					my $vm = Vim::find_entity_view(view_type=>'VirtualMachine', filter => { name => $name} );
					if ( ! defined($vm) ) {
						print "Folder path does not exist: $folder\n";
					}
				}
			}
		}
	}
}
#    print_browse(mor => $host_data_browser, filePath => '[' . $datastore->summary->name . ']', level => 0);
# $browse_task = $datastore_mor->SearchDatastoreSubFolders(datastorePath=>$path);


# Disconnect from the server
Util::disconnect();
# To mitigate SSL warnings by default
BEGIN {
	$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
}
