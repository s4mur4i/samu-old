#!/usr/bin/perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use SDK::GuestManagement;
use VMware::VIRuntime;
my %opts = (
	ticket => {
		type => '=s',
		help => 'Ticket to power on',
		required => 0,
	},
        vmname => {
                type => "=s",
                help => "Vm to turn on",
                required => 0,
        },

);
Opts::add_options(%opts);
Opts::parse();
Opts::validate();
my $username = Opts::get_option('username');
my $password = Opts::get_option('password');
my $url = Opts::get_option('url');
my $ticket = Opts::get_option('ticket');
my $vmname = Opts::get_option('vmname');
Util::connect( $url, $username, $password );
if (defined($ticket) && ! defined($vmname) ) {
	my $machines = Vim::find_entity_views(view_type =>'VirtualMachine',filter=>{ name => qr/^$ticket-/});
	if ( @$machines == 0 ) {
		Util::trace( 0, "Ticket machines cannot be found.\n" );
		exit 1;
	}
	foreach (@$machines) {
		Util::trace( 0, "Machine: ". $_->name ."\n" );
		eval { &GuestManagement::poweron_vm($_->name); };
		if ($@) { &Error::catch_ex( $@ ); }
	}
} elsif ( defined($vmname) && ! defined($ticket)) {
        Util::trace( 0, "Power on single vm: $vmname\n" );
        eval { &GuestManagement::poweron_vm($vmname); } ;
	if ($@) { &Error::catch_ex( $@ ); }
} elsif ( defined($vmname) && defined($ticket) ) {
        Util::trace( 0, print "To delete the ticket $ticket or to delete the vm $vmname... that is the question.\n" );
        exit 1;
} else {
        Util::trace( 0, "I don't know what to do....\n" );
        exit 1;
}

# Disconnect from the server
Util::disconnect();
# To mitigate SSL warnings by default
BEGIN {
	$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
}
