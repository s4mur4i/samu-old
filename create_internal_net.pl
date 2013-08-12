#!/usr/bin/perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use SDK::Support;
use SDK::Misc;
use SDK::GuestManagement;
use VMware::VIRuntime;
use Data::Dumper;

my %opts = (
	vmname => {
		type => "=s",
		help => "List of vms to put in one internal interface. Machines should be comma seperated. Example: test1,test2,test3",
		required => 1,
	},
	ticket =>  {
                type => "=s",
                help => "ticket to reference the machines",
                required => 0,
        },
);
Opts::add_options(%opts);
Opts::parse();
Opts::validate();
my $username = Opts::get_option('username');
my $password = Opts::get_option('password');
my $url = Opts::get_option('url');
Util::connect( $url, $username, $password );
my $vm = Opts::get_option('vmname');
my $req_ticket = Opts::get_option('ticket');
my @vm = split(',',$vm);
my $name;
foreach (@vm) {
	my $machine = Vim::find_entity_view(view_type=>'VirtualMachine', filter=> {name => $_});
	if (!defined($machine)) {
		print "Cannot find machine: $_";
		next;
	}
	my ($ticket, $username, $family, $version, $lang, $arch, $type , $uniq) = &Misc::vmname_splitter($machine->name);
	if (defined($req_ticket)) {
		$ticket = $req_ticket;
	}
	if ( !defined($ticket)) {
		print "Could not parse name from VM, or no ticket information specified.\n";
		next;
	}
	if (!defined($name)) {
		$name = $ticket . "-int-" . &Misc::random_3digit;
		while (&GuestManagement::dvportgroup_status($name)) {
			$name = $ticket . "-int-" . &Misc::random_3digit;
		}
		&GuestManagement::create_dvportgroup($name,$ticket);
	}
	if ( $type eq "xcb" ) {
		&GuestManagement::change_network_interface($machine->name,1,$name);
	} else {
		&GuestManagement::change_network_interface($machine->name,0,$name);
	}
}
# Disconnect from the server
Util::disconnect();
# To mitigate SSL warnings by default
BEGIN {
	$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
}
