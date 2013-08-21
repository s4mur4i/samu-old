#!/usr/bin/perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use SDK::Vcenter;
use SDK::Misc;
use SDK::GuestManagement;
use VMware::VIRuntime;
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
$vmname = Vim::find_entity_view(view_type=>'VirtualMachine', properties => [ 'name' ], filter=> {name => $vmname});
if (!defined($vmname) ) {
        Util::trace( 0, "Cannot find VM\n" );
	exit 1;
}
while ($count > 0) {
	eval { &GuestManagement::add_network_interface($vmname->name); };
	if ($@) { &Error::catch_ex( $@ ); }
	$count--;
}
# Disconnect from the server
Util::disconnect();
# To mitigate SSL warnings by default
BEGIN {
	$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
}
