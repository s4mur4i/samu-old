#!/usr/bin/perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use SDK::GuestManagement;
use VMware::VIRuntime;
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
);
Opts::add_options(%opts);
Opts::parse();
Opts::validate();
my $username = Opts::get_option('username');
my $password = Opts::get_option('password');
my $url = Opts::get_option('url');
my $vmname = Opts::get_option('vmname');
my $num = Opts::get_option('num');
Util::connect( $url, $username, $password );
&GuestManagement::remove_cdrom_iso($vmname, $num);
# Disconnect from the server
Util::disconnect();
# To mitigate SSL warnings by default
BEGIN {
	$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
}
