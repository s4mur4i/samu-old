#!/usr/bin/perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use lib '/usr/lib/vmware-vcli/apps';
use SDK::GuestManagement;
use VMware::VICommon;
use VMware::VIRuntime;
use Data::Dumper;
my %opts = (
	vmname => {
		type => '=s',
		help => 'Vm to change CDrom',
		required => 1,
	},
	num => {
		type => '=s',
                help => 'Number of CD rom to change',
                required => 0,
		default => "0",
	},
	iso => {
		type => '=s',
                help => 'Datastore path to change. Example: [lofasz] lofasz/lofasz.iso',
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
my $num = Opts::get_option('num');
my $iso = Opts::get_option('iso');
Util::connect( $url, $username, $password );
&GuestManagement::change_cdrom_to_iso($vmname, $num,$iso);
# Disconnect from the server
Util::disconnect();
# To mitigate SSL warnings by default
BEGIN {
	$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
}
