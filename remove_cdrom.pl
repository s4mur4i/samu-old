#!/usr/bin/perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use SDK::GuestManagement;
use VMware::VIRuntime;
#use Data::Dumper;
my %opts = (
	vmname => {
                type => "=s",
                help => "Name of vm to remove cdrom",
                required => 1,
        },
        number => {
                type => "=s",
                help => "Number of cdrom to remove",
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
my $number = Opts::get_option('number');
$vmname = Vim::find_entity_view(view_type=>'VirtualMachine', properties => [ 'name' ], filter=> {name => $vmname});
if (!defined($vmname) ) {
        Util::trace( 0, "Cannot find VM\n" );
        exit 1;
}
eval { &GuestManagement::remove_cdrom($vmname->name,$number); };
if ($@) { &Error::catch_ex( $@ ); }
# Disconnect from the server
Util::disconnect();
# To mitigate SSL warnings by default
BEGIN {
	$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
}
