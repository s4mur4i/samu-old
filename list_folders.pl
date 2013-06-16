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
my $vm = Opts::get_option('vm');
my $url = Opts::get_option('url');
Util::connect( $url, $username, $password );
my ($datacenter_views, $vmFolder_view, $indent);
$indent = 0;
$datacenter_views = Vim::find_entity_views( view_type => 'Datacenter', properties => ["name", "vmFolder"]);
foreach ( @{$datacenter_views} )
{
	print "Datacenter: " . $_->name . "\n";
	TraverseFolder($_->vmFolder, $indent);
}

sub TraverseFolder
{
	my ($entity_moref, $index) = @_;
	my ($num_entities, $entity_view, $child_view, $i, $mo);
	$index += 2;
	$entity_view = Vim::get_view( mo_ref => $entity_moref, properties => ['name', 'childEntity']);
	$num_entities = defined($entity_view->childEntity) ? @{$entity_view->childEntity} : 0;
	if ( $num_entities > 0 ) {
		foreach $mo ( @{$entity_view->childEntity} ) {
			$child_view = Vim::get_view( mo_ref => $mo, properties => ['name']);
			if ( $child_view->isa("VirtualMachine") ) {
				print " " x $index . "Virtual Machine: " . $child_view->name . "\n" ;
			}

			if ( $child_view->isa("Folder") ) {
				print " " x $index . "Folder: " . $child_view->name . "\n";
				$child_view = Vim::get_view(
					mo_ref => $mo, properties => ['name', 'childEntity']
				);
				TraverseFolder($mo, $index);
			}
		}
	}
}
# Disconnect from the server
Util::disconnect();
# To mitigate SSL warnings by default
BEGIN {
	$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
}
