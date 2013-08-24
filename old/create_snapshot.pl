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
		help => 'Name of vm',
		required => 1,
	},
	name => {
		type => '=s',
		help => 'Name of snapshot',
		required => 0,
		default => 'snapshot',
	},
	description => {
		type => '=s',
		help => 'Description of snapshot',
		required => 0,
		default => 'My little snapshot',
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
my $description = Opts::get_option('description');
Util::connect( $url, $username, $password );
eval { &GuestManagement::create_snapshot($vmname,$name,$description); };
if ($@) { &Error::catch_ex( $@ ); }
# Disconnect from the server
Util::disconnect();
# To mitigate SSL warnings by default
BEGIN {
	$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
}
