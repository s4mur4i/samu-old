#!/usr/bin/perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use lib '/usr/lib/vmware-vcli/apps';
use SDK::Auto;
use SDK::GuestInternal;
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
my $workdir='c:\\';
my $env='PATH=C:\windows\system32';
my $prog='C:\windows\system32\cmd.exe';
my $arg = "/c dnscmd /zoneprint $Auto::dns{$zone}{'domain'} >C:/dns.out";
my $pid = &GuestInternal::runCommandInGuest( $Auto::dns{$zone}{'vmname'}, $prog, $arg, $env, $workdir, $Auto::dns{$zone}{'username'}, $Auto::dns{$zone}{'password'} );
print "pid is: $pid\n";
&GuestInternal::transfer_from_guest( $Auto::dns{$zone}{'vmname'}, "C:/dns.out", "/tmp/dns.out", $Auto::dns{$zone}{'username'}, $Auto::dns{$zone}{'password'} );

# Disconnect from the server
Util::disconnect();
# To mitigate SSL warnings by default
BEGIN {
	$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
}
