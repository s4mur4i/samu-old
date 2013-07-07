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
	vmname => {
		type => '=s',
		help => 'Which VMs cdrom to list.',
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
        print "Cannot find VM\n";
        exit 1;
}
my $count = &GuestManagement::count_cdrom($vmname->name);
my $numb = 0;
while ($count > 0) {
        my ($key,$backing,$label) = &GuestManagement::get_cdrom($vmname->name,$numb);
        print "$numb\t$key\t$backing\t$label\n";
        $count--;
        $numb++;
}


# Disconnect from the server
Util::disconnect();
# To mitigate SSL warnings by default
BEGIN {
	$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
}
