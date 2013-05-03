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

sub single($) {
        my ($vmname) = @_;
        $vmname = Vim::find_entity_view( view_type => 'VirtualMachine', filter => { name => $vmname});
	eval {
		$vmname->Destroy_Task;
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
	print "Vm deleted succsfully: " . $vmname->name . "\n";
};

sub ticket($) {
	my ($ticket) = @_;
	my $vm_views = Vim::find_entity_views( view_type => 'VirtualMachine', filter => { name => qr/^$ticket-/ });
	if ( @$vm_views ) {
		foreach (@$vm_views) {
			print "Going to delete follwoing vm: " . $_->name . "\n";
			&single($_->name);
		}
	} else {
		print "No vm referenced to this ticket: $ticket\n";
		exit 2;
	};
};

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
	ticket => {
		type => "=s",
		help => "The ticket resource pool",
		required => 0,
	},
	vmname => {
		type => "=s",
		help => "The destination pool we should move the resouce pool",
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
my $ticket = Opts::get_option('ticket');
my $vmname = Opts::get_option('vmname');

if (defined($ticket) && ! defined($vmname) ) {
	print "Delete ticket content: $ticket\n";
	&ticket($ticket);
} elsif ( defined($vmname) && ! defined($ticket)) {
	print "Delete single vm: $vmname\n";
	&single($vmname) ;
} elsif ( defined($vmname) && defined($ticket) ) {
	print "To delete the ticket $ticket or to delete the vm $vmname... that is the question.\n";
	exit 1;
} else {
	print "I don't know what to do....\n";
	exit 1;
}

# Disconnect from the server
Util::disconnect();
# To mitigate SSL warnings by default
BEGIN {
	$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
}
