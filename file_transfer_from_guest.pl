#!/usr/bin/perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use lib '/usr/lib/vmware-vcli/apps';
use SDK::Support;
use SDK::GuestInternal;
use VMware::VICommon;
use VMware::VIRuntime;
use Data::Dumper;
use LWP::Simple;

my %opts = (
        vmname => {
                type => "=s",
                help => "Name of VM",
                required => 1,
        },
        guestusername => {
                type => "=s",
                help => "Username for guest OS",
                required => 0,
        },
        guestpassword => {
                type => "=s",
                help => "Password for guest OS",
                required => 0,
        },
	path => {
		type => "=s",
                help => "Path to file to download on guest",
                required => 1,
	},
	dest => {
		type => "=s",
		help => "Destination file to download file.",
		required =>0,
	},
);
Opts::add_options(%opts);
Opts::parse();
Opts::validate();
my $username = Opts::get_option('username');
my $password = Opts::get_option('password');
my $vmname = Opts::get_option('vmname');
my $url = Opts::get_option('url');
Util::connect( $url, $username, $password );
my $path = Opts::get_option('path');
my $dest= Opts::get_option('dest');
my $guestusername = Opts::get_option('guestusername');
my $guestpassword = Opts::get_option('guestpassword');
if ( $guestusername != 0 and $guestpassword != 0 ) {
        &GuestInternal::tranfer_to_guest( $vmname, $path, $dest, $guestusername, $guestpassword );
} else {
        &GuestInternal::tranfer_to_guest( $vmname, $path, $dest );
}
# Disconnect from the server
Util::disconnect();
# To mitigate SSL warnings by default
BEGIN {
	$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
}
