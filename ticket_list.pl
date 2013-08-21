#!/usr/bin/perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use SDK::Misc;
use LWP::Simple qw(get);
use SDK::Kayako;
use SDK::Bugzilla;
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
my $machines = Vim::find_entity_views(view_type =>'VirtualMachine', properties => [ 'name' ] );
my %tickets=();
eval {
my $dbh = &Kayako::connect_kayako();
if ($@) { &Error::catch_ex( $@ ); }
foreach (@$machines) {
	my ($ticket, $username, $family, $version, $lang, $arch, $type , $uniq) = &Misc::vmname_splitter($_->name);
	if ( defined($ticket) and  !defined($tickets{$ticket}) ) {
		$tickets{$ticket}=$username;
	}
}
for my $ticket ( sort (keys %tickets) ) {
	if ( $ticket ne "" and $ticket ne "unknown" ) {
		Util::trace( 0, "Ticket: $ticket, owner: $tickets{$ticket}" );
		my $result = &Kayako::run_query( $dbh, "select ticketstatustitle from swtickets where ticketid = '$ticket'" );
		## need to implement multiple tickets in field seperated by space
		if ( !defined( $result ) ) {
			print "\n";
		} else {
			Util::trace( 0, ", ticket status: " . $$result{ticketstatustitle} ."" );
			$result = &Kayako::run_query( $dbh, "select fieldvalue from swcustomfieldvalues where typeid = '$ticket' and customfieldid = '25'" );
			if ( !defined($result) or $$result{fieldvalue} eq "" ) {
				print "\n";
			} else {
				my @result = split( " ", $$result{fieldvalue} );
				foreach ( @result ) {
					#print " result: '$_'\n";
					if ( $_ eq "" ) {
						Util::trace( 0, "\n" );
					} else {
						my $id;
						if ($_ =~ /^\s*\d+\s*$/ ) {
							$id = $_;
						} elsif ($_ =~ /\?id=\d+/ ) {
							( $id ) = $_ =~ /id=(\d+)\D?/ ;
						} else {
							$id = $_;
						}
						Util::trace( 0, ", bugzilla: " . $id );
						my $content = &Bugzilla::bugzilla_status( $id );
						if ( !defined( $content ) ) {
							Util::trace( 0, "\n" );
						} else {
							Util::trace( 0, ", bugzilla status: $content\n" );
						}

					}
				}
			}
		}
	}
}
&Kayako::disconnect_kayako($dbh);
};
if ($@) { &Error::catch_ex( $@ ); }
# Disconnect from the server
Util::disconnect();
# To mitigate SSL warnings by default
BEGIN {
	$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
}
