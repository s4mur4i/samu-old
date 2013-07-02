#!/usr/bin/perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use VMware::VICommon;
use VMware::VIRuntime;
use Data::Dumper;

my %opts = (
	vmname => {
		type => "=s",
		help => "Vm info",
		required => 1,
	},
);
Opts::add_options(%opts);
Opts::parse();
Opts::validate();
my $username = Opts::get_option('username');
my $password = Opts::get_option('password');
my $datacenter = Opts::get_option('datacenter');
my $vm = Opts::get_option('vmname');
my $url = Opts::get_option('url');
Util::connect( $url, $username, $password );
my $vminfo = Vim::find_entity_view(view_type=>'VirtualMachine', filter=> {name => $vm});
if ( defined($vminfo) ) {
	print "Vminfo is: " . Dumper($vminfo);
} else {
	print "No vm under name : $vm\n";
}
# Disconnect from the server
Util::disconnect();
# To mitigate SSL warnings by default
BEGIN {
	$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
}
