#!/usr/bin/perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use SDK::GuestManagement;
use SDK::Misc;
use VMware::VICommon;
use VMware::VIRuntime;
use Data::Dumper;

my %opts = (
	vmname => {
		type => "=s",
		help => "",
		required => 1,
	},
);
Opts::add_options(%opts);
Opts::parse();
Opts::validate();
my $username = Opts::get_option('username');
my $password = Opts::get_option('password');
my $url = Opts::get_option('url');
Util::connect( $url, $username, $password );
my $vmname = Opts::get_option('vmname');
my @vmname = split(',',$vmname);
my $dv_name;
foreach (@vmname) {
	my $vm_view = Vim::find_entity_view(view_type=>'VirtualMachine', filter=> {name => $_});
	my ($ticket, $username, $family, $version, $lang, $arch, $type , $uniq) = &Misc::vmname_splitter($_);
	if ( !defined($vm_view)) {
		print "Machine not defined:" .$_ ."\n";
		next;
	}
	if (!defined($ticket)) {
		print "Cannot parse ticket.\n";
		next;
	}
	if (!defined($dv_name)) {
                $dv_name = $ticket . "-ha-" . &Misc::random_3digit;
                while (&GuestManagement::dvportgroup_status($dv_name)) {
                        $dv_name = $ticket . "-ha-" . &Misc::random_3digit;
                }
                &GuestManagement::create_dvportgroup($dv_name,$ticket);
        }
	if ( $type eq "xcb" ) {
		&GuestManagement::change_network_interface($_,3,$dv_name);
	} else {
		print "Not XCB product. Not building HA with it\n";
		next;
	}
}
# Disconnect from the server
Util::disconnect();
# To mitigate SSL warnings by default
BEGIN {
	$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
}
