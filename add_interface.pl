#!/usr/bin/perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
#use lib '/usr/lib/vmware-vcli/apps';
use SDK::Vcenter;
use SDK::Misc;
use SDK::GuestManagement;
use VMware::VICommon;
use VMware::VIRuntime;
#use Data::Dumper;
my %opts = (
        vmname => {
                type => "=s",
                help => "Name of vm to add interface",
                required => 1,
        },
        count => {
                type => "=s",
                help => "Number of interfaces to add",
                required => 0,
		default => "1",
	},
);
Opts::add_options(%opts);
Opts::parse();
Opts::validate();
my $username = Opts::get_option('username');
my $password = Opts::get_option('password');
my $url = Opts::get_option('url');
Util::connect( $url, $username, $password );
my $vmname = Opts::get_option('vmname');
my $count = Opts::get_option('count');
$vmname = Vim::find_entity_view(view_type=>'VirtualMachine', filter=> {name => $vmname});
if (!defined($vmname) ) {
        print "Cannot find VM\n";
	exit 1;
}

&Management::add_network_interface;
# Disconnect from the server
Util::disconnect();
# To mitigate SSL warnings by default
BEGIN {
	$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
}
