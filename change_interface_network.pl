#!/usr/bin/perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use lib '/usr/lib/vmware-vcli/apps';
use SDK::GuestManagement;
use VMware::VICommon;
use VMware::VIRuntime;
#use Data::Dumper;
my %opts = (
        vmname => {
                type => "=s",
                help => "Name of vm to remove interface",
                required => 1,
        },
        number => {
                type => "=s",
                help => "Number of interfaces to remove",
                required => 1,
        },
	network => {
                type => "=s",
                help => "Network name to change to",
                required => 1,
        },
);
Opts::add_options(%opts);
Opts::parse();
Opts::validate();
my $username = Opts::get_option('username');
my $password = Opts::get_option('password');
my $url = Opts::get_option('url');
my $vmname = Opts::get_option('vmname');
my $number = Opts::get_option('number');
my $network = Opts::get_option('network');
Util::connect( $url, $username, $password );
$vmname = Vim::find_entity_view(view_type=>'VirtualMachine', filter=> {name => $vmname});
if (!defined($vmname) ) {
        print "Cannot find VM\n";
        exit 1;
}
$network = Vim::find_entity_view(view_type=>'Network', filter=> {name => $network});
if (!defined($network) ) {
        print "Cannot find network\n";
        exit 1;
}
&GuestManagement::change_network_interface($vmname->name,$number,$network->name);
# Disconnect from the server
Util::disconnect();
# To mitigate SSL warnings by default
BEGIN {
	$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
}
