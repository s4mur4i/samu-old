#!/usr/bin/perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use lib '/usr/lib/vmware-vcli/apps';
use SDK::Misc;
use LWP::Simple qw(get);
use SDK::Kayako;
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
my $machines = Vim::find_entity_views(view_type =>'VirtualMachine', properties => [ 'name' ] );
my %tickets=();
my $dbh = &Kayako::connect_kayako();
foreach (@$machines) {
	my ($ticket, $username, $family, $version, $lang, $arch, $type , $uniq) = &Misc::vmname_splitter($_->name);
	if ( defined($ticket) and  !defined($tickets{$ticket}) ) {
		$tickets{$ticket}=$username;
	}
}
for my $ticket ( sort (keys %tickets) ) {
	if ( $ticket ne "" and $ticket ne "unknown" ) {
		print "Ticket: $ticket, owner: $tickets{$ticket}";
		my $result = &Kayako::run_query( $dbh, "select ticketstatustitle from swtickets where ticketid = '$ticket'" );
		if ( !defined( $result ) ) {
			print "\n";
		} else {
			print ", ticket status: " . $$result{ticketstatustitle} ."";
			$result = &Kayako::run_query( $dbh, "select fieldvalue from swcustomfieldvalues where typeid = '$ticket' and customfieldid = '25'" );
		#print Dumper($result);
			if ( !defined( $result ) or $$result{fieldvalue} eq "" ) {
				print "\n";
			} else {
				my $id;
				if ($$result{fieldvalue} =~ /^\s*\d+\s*$/ ) {
					$id = $$result{fieldvalue};
				} elsif ($$result{fieldvalue} =~ /\?id=\d+/ ) {
					( $id ) = $$result{fieldvalue} =~ /id=(\d+)\D?/ ;
				} else {
					$id = $$result{fieldvalue};
				}
				print ", bugzilla: " . $id;
				my $url = "http://bugzilla.balabit/bugzilla-3.0/show_bug.cgi?id=$id";
				my $content;
				for my $line ( split qr/\R/, get( $url ) ) {
					( $content ) = $line =~ /\s*<span id="static_bug_status">(\w+)/ if ( $line =~ /<span id="static_bug_status">/ ) ;
				}
				if ( !defined( $content ) ) {
					print "\n";
				} else {
					print ", bugzilla status: $content\n";
				}

			}
		}
	}
}
&Kayako::disconnect_kayako($dbh);
# Disconnect from the server
Util::disconnect();
# To mitigate SSL warnings by default
BEGIN {
	$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
}
