#!/usr/bin/perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use SDK::GuestManagement;
use VMware::VIRuntime;
my %opts = (
	vmname => {
		type => '=s',
		help => 'Which VMs disk to list.',
		required=> '1',
	},
);
Opts::add_options(%opts);
Opts::parse();
Opts::validate();
my $username = Opts::get_option('username');
my $password = Opts::get_option('password');
my $url = Opts::get_option('url');
my $vmname = Opts::get_option('vmname');
Util::connect( $url, $username, $password );
$vmname = Vim::find_entity_view(view_type=>'VirtualMachine', filter=> {name => $vmname});
if (!defined($vmname) ) {
        Util::trace( 0, "Cannot find VM\n" );
        exit 1;
}
eval {
my $count = &GuestManagement::count_disk($vmname->name);
my $numb = 0;
while ($count > 0) {
        my ($key,$size,$path) = &GuestManagement::get_disk($vmname->name,$numb);
        Util::trace( 0, "$numb\t$key\t$size KB\t$path\n" );
        $count--;
        $numb++;
}
};
if ($@) { &Error::catch_ex( $@ ); }

# Disconnect from the server
Util::disconnect();
# To mitigate SSL warnings by default
BEGIN {
	$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
}
