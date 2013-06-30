#!/usr/bin/perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use lib '/usr/lib/vmware-vcli/apps';
use SDK::GuestManagement;
use SDK::Misc;
use VMware::VICommon;
use VMware::VIRuntime;
my %opts = (
        ticket => {
                type => "=s",
                help => "Name of vm to remove interface",
                required => 1,
        },
);
Opts::add_options(%opts);
Opts::parse();
Opts::validate();
my $username = Opts::get_option('username');
my $password = Opts::get_option('password');
my $url = Opts::get_option('url');
my $ticket = Opts::get_option('ticket');
Util::connect( $url, $username, $password );
my $random = &Misc::random_3digit();
my $name = $ticket . "-cust-" . $random;
while ( &GuestManagement::dvportgroup_status($name) ) {
	$random = &Misc::random_3digit();
	$name = $ticket . "-" . $random;
}
print "Port group name is going to be: $name\n";
&GuestManagement::create_dvportgroup($name,$ticket);
# Disconnect from the server
Util::disconnect();
# To mitigate SSL warnings by default
BEGIN {
	$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
}
