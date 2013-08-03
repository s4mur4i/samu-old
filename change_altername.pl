#!/usr/bin/perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use lib '/usr/lib/vmware-vcli/apps';
use SDK::GuestManagement;
use VMware::VICommon;
use VMware::VIRuntime;
my %opts = (
	vmname => {
		type => "=s",
		required => 1,
		help => "Vms alternate name to change",
	},
	name => {
		type => "=s",
		required => 1,
		help => "Name to set",
	},
);
Opts::add_options(%opts);
Opts::parse();
Opts::validate();
my $username = Opts::get_option('username');
my $password = Opts::get_option('password');
my $url = Opts::get_option('url');
my $vmname = Opts::get_option('vmname');
my $name = Opts::get_option('name');
Util::connect( $url, $username, $password );
&GuestManagement::change_altername($vmname,$name);
# Disconnect from the server
Util::disconnect();
# To mitigate SSL warnings by default
BEGIN {
	$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
}