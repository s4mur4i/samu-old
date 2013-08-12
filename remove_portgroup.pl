#!/usr/bin/perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use SDK::GuestManagement;
use VMware::VIRuntime;
my %opts = (
        name => {
                type => "=s",
                help => "Name of port group to remove",
                required => 1,
        },
);
Opts::add_options(%opts);
Opts::parse();
Opts::validate();
my $username = Opts::get_option('username');
my $password = Opts::get_option('password');
my $url = Opts::get_option('url');
my $name = Opts::get_option('name');
Util::connect( $url, $username, $password );
my $portgroup = Vim::find_entity_views( view_type => 'DistributedVirtualPortgroup', filter=>{ name=>$name});
if (defined($portgroup)) {
	print "Removing\n";
	&GuestManagement::remove_dvportgroup($name);
} else {
	print "No network under name: $name\n";
}
# Disconnect from the server
Util::disconnect();
# To mitigate SSL warnings by default
BEGIN {
	$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
}
