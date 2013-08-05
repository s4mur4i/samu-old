#!/usr/bin/perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use lib '/usr/lib/vmware-vcli/apps';
use SDK::Auto;
use VMware::VICommon;
use VMware::VIRuntime;
my %opts = (
	zone => {
		type => '=s',
		help => "Which DNS to list: dev (support.balabit) / prod(ittest.balabit)",
		default => 'dev',
	},
);
Opts::add_options(%opts);
Opts::parse();
Opts::validate();
my $username = Opts::get_option('username');
my $password = Opts::get_option('password');
my $url = Opts::get_option('url');
my $zone = Opts::get_option('zone');

if ( $zone eq 'dev' ) {
	print "Development dns zone.\n";
	$zone = "dev_ad";
} elsif( $zone eq 'prod' ) {
	print "Production dns zone.\n";
	$zone = "prod_ad";
} else {
	print "Unknown dns zone.\n";
	exit 1;
}
Util::connect( $url, $username, $password );
&Auto::list_dns( $zone );
# Disconnect from the server
Util::disconnect();
# To mitigate SSL warnings by default
BEGIN {
	$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
}
