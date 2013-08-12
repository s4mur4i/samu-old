#!/usr/bin/perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use SDK::Vcenter;
use VMware::VIRuntime;
my %opts = (
	name => {
                type => "=s",
                help => "Name of resource pool to create",
                required => 1,
	},
	parent => {
		type => "=s",
		help => "Name of parent resource pool",
		required => 0,
		default => 'Resources',
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
my $parent = Opts::get_option('parent');
if (!&Vcenter::exists_resource_pool($parent)) {
	print "Parent Cannot be found.\n";
	exit 3;
}
if ( !&Vcenter::create_resource_pool($name,$parent)) {
	exit 3;
}
# Disconnect from the server
Util::disconnect();
# To mitigate SSL warnings by default
BEGIN {
	$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
}
