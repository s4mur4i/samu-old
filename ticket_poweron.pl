#!/usr/bin/perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use lib '/usr/lib/vmware-vcli/apps';
use SDK::GuestManagement;
use VMware::VICommon;
use VMware::VIRuntime;
my %opts = (
	ticket => {
		type => '=s',
		help => 'Ticket to power on',
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
my $machines = Vim::find_entity_views(view_type =>'VirtualMachine',filter=>{ name => qr/^$ticket-/});
if ( @$machines == 0 ) {
	print "Ticket machines cannot be found.\n";
	exit 1;
}
foreach (@$machines) {
	print "Machine: ". $_->name ."\n";
        &GuestManagement::poweron_vm($_->name);
}
# Disconnect from the server
Util::disconnect();
# To mitigate SSL warnings by default
BEGIN {
	$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
}
