#!/usr/bin/perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use SDK::Support;
use SDK::GuestInternal;
use SDK::Misc;
use VMware::VIRuntime;
use Data::Dumper;
use HTTP::Request;
use LWP::UserAgent;

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
                help => "Path to file to upload on guest",
                required => 1,
	},
	dest => {
		type => "=s",
		help => "Upload destination file.",
		required => 1,
	},
	overwrite => {
		type => "",
		help => "Should files be overwritten",
		required => 0,
	},
);
Opts::add_options(%opts);
Opts::parse();
Opts::validate();
my $username = Opts::get_option('username');
my $password = Opts::get_option('password');
my $vmname = Opts::get_option('vmname');
my $url = Opts::get_option('url');
my $guestusername = Opts::get_option('guestusername');
my $guestpassword = Opts::get_option('guestpassword');
my $path = Opts::get_option('path');
my $dest = Opts::get_option('dest');
my $overwrite = Opts::get_option('overwrite');
Util::connect( $url, $username, $password );
eval {
if ( ( defined( $guestusername ) and defined( $guestpassword ) ) and ( $guestusername ne "" and $guestpassword ne "" ) ) {
	&GuestInternal::transfer_to_guest( $vmname, $path, $dest, $overwrite, $guestusername, $guestpassword );
} else {
	&GuestInternal::transfer_to_guest( $vmname, $path, $dest, $overwrite );
}
};
if ($@) { &Error::catch_ex( $@ ); }
# Disconnect from the server
Util::disconnect();
# To mitigate SSL warnings by default
BEGIN {
	$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
}
