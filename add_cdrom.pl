#!/usr/bin/perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use SDK::Misc;
use SDK::GuestManagement;
use VMware::VIRuntime;
my %opts = (
        vmname => {
                type => "=s",
                help => "Name of vm to add disk",
                required => 1,
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
$vmname = Vim::find_entity_view(view_type=>'VirtualMachine', filter=> {name => $vmname});
if (!defined($vmname) ) {
        print "Cannot find VM\n";
	exit 1;
}
&GuestManagement::add_cdrom($vmname->name);
# Disconnect from the server
Util::disconnect();
# To mitigate SSL warnings by default
BEGIN {
	$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
}
