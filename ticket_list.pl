#!/usr/bin/perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use lib '/usr/lib/vmware-vcli/apps';
use SDK::Misc;
use VMware::VICommon;
use VMware::VIRuntime;
my %opts = (
);
Opts::add_options(%opts);
Opts::parse();
Opts::validate();
my $username = Opts::get_option('username');
my $password = Opts::get_option('password');
my $url = Opts::get_option('url');
Util::connect( $url, $username, $password );
my $machines = Vim::find_entity_views(view_type =>'VirtualMachine');
my %tickets=();
foreach (@$machines) {
	my ($ticket, $username, $family, $version, $lang, $arch, $type , $uniq) = &Misc::vmname_splitter($_->name);
	if ( defined($ticket) and  !defined($tickets{$ticket}) ) {
		$tickets{$ticket}=$username;
	}
}
for my $ticket ( sort (keys %tickets) ) {
	if ( $ticket ne "" and $ticket ne "unknown" ) {
		print "Ticket: $ticket, owner: $tickets{$ticket}\n";
	}
}
# Disconnect from the server
Util::disconnect();
# To mitigate SSL warnings by default
BEGIN {
	$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
}
