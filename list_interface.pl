#!/usr/bin/perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use SDK::GuestManagement;
use VMware::VIRuntime;
my %opts = (
        vmname => {
                type => "=s",
                help => "Name of vm to list interface",
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
Util::connect( $url, $username, $password );
$vmname = Vim::find_entity_view(view_type=>'VirtualMachine', filter=> {name => $vmname});
if (!defined($vmname) ) {
        Util::trace( 0, "Cannot find VM\n" );
        exit 1;
}
eval {
my $count = &GuestManagement::count_network_interface($vmname->name);
my $numb = 0;
while ($count > 0) {
	my ($key, $unitnumber, $controllerkey, $mac) = &GuestManagement::get_network_interface($vmname->name,$numb);
	my ($network, $label) = &GuestManagement::get_ext_network_interface($vmname->name,$numb);
	Util::trace( 0, "$numb\t$key\t$mac\t$network\t$label\n" );
	$count--;
	$numb++;
}
};
if ($@) { &Error::catch_ex( $@ ); }
# Disconnect from the server
Util::disconnect();
# To mitigate SSL warnings by default
BEGIN {
	$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
}
