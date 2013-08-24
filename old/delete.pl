#!/usr/bin/perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use SDK::Vcenter;
use VMware::VIRuntime;
use Data::Dumper;

sub ticket($) {
	my ($ticket) = @_;
	my $vm_views = Vim::find_entity_views( view_type => 'VirtualMachine', properties => [ 'name' ], filter => { name => qr/^$ticket-/ });
	if ( @$vm_views ) {
		foreach (@$vm_views) {
			Util::trace( 0, "Going to delete follwoing vm: " . $_->name . "\n" );
			eval { &Vcenter::delete_virtualmachine($_->name); };
			if ($@) { &Error::catch_ex( $@ ); }
		}
	} else {
		Util::trace( 0, "No vm referenced to this ticket: $ticket\n" );
		exit 2;
	};
};

my %opts = (
	ticket => {
		type => "=s",
		help => "The ticket resource pool",
		required => 0,
	},
	vmname => {
		type => "=s",
		help => "The destination pool we should move the resouce pool",
		required => 0,
	},
);
Opts::add_options(%opts);
Opts::parse();
Opts::validate();
my $username = Opts::get_option('username');
my $password = Opts::get_option('password');
my $url = Opts::get_option('url');
Util::connect( $url, $username, $password );
my $ticket = Opts::get_option('ticket');
my $vmname = Opts::get_option('vmname');

if (defined($ticket) && ! defined($vmname) ) {
	Util::trace( 0, "Delete ticket content: $ticket\n" );
	&ticket($ticket);
} elsif ( defined($vmname) && ! defined($ticket)) {
	Util::trace( 0, "Delete single vm: $vmname\n" );
	eval { &Vcenter::delete_virtualmachine($vmname) ; };
	if ($@) { &Error::catch_ex( $@ ); }
} elsif ( defined($vmname) && defined($ticket) ) {
	Util::trace( 0, "To delete the ticket $ticket or to delete the vm $vmname... that is the question.\n" );
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
