#!/usr/bin/perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use lib '/usr/lib/vmware-vcli/apps';
use SDK::Vcenter;
use VMware::VICommon;
use VMware::VIRuntime;
my %opts = (
	name => {
                type => "=s",
                help => "The resource pool to delete",
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
my $name = Opts::get_option('name');
if (&Vcenter::exists_resource_pool($name)) {
	print "Resource pool exists, deleting\n";
	if (&Vcenter::check_if_empty_resource_pool($name)) {
                &Vcenter::delete_resource_pool($name);
        } else {
		print "Resource pool not empty. Clean up first\n";
	}
} else {
	print "Cannot find resource pool\n";
}
# Disconnect from the server
Util::disconnect();
# To mitigate SSL warnings by default
BEGIN {
	$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
}
