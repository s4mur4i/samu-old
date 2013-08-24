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
		help => 'Name of snapshot to remove //not implemented yet',
		required => 0,
	},
	id => {
		type => '=s',
		help => 'ID of snapshot to remove',
		required => 0,
	}
);
Opts::add_options(%opts);
Opts::parse();
Opts::validate();
my $username = Opts::get_option('username');
my $password = Opts::get_option('password');
my $url = Opts::get_option('url');
my $vmname = Opts::get_option('vmname');
my $name = Opts::get_option('name');
my $id = Opts::get_option('id');
if ( defined($name) && defined($id) ) {
	Util::trace( 0, "Both name and id defined.\n" );
	exit 1;
} elsif (!defined($name) && !defined($id)) {
	Util::trace( 0, "Id or name not defined.\n" );
	exit 1;
}
Util::connect( $url, $username, $password );
eval { &GuestManagement::revert_to_snapshot($vmname, $id); };
if ($@) { &Error::catch_ex( $@ ); }
# Disconnect from the server
Util::disconnect();
# To mitigate SSL warnings by default
BEGIN {
	$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
}
