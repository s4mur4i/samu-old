#!/usr/bin/perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use SDK::Vcenter;
use VMware::VIRuntime;
use Data::Dumper;

my %opts = (
);
Opts::add_options(%opts);
Opts::parse();
Opts::validate();
my $username = Opts::get_option('username');
my $password = Opts::get_option('password');
my $url = Opts::get_option('url');
Util::connect( $url, $username, $password );
print "Resouce Pool cleanup\n";
my $rp_pools = Vim::find_entity_views( view_type => 'ResourcePool');
foreach my $pool (@$rp_pools) {
	if (&Vcenter::check_if_empty_resource_pool($pool->name)) {
		print "Deleting resource pool:". $pool->name ."\n";
		&Vcenter::delete_resource_pool($pool->name);
	}
}
print "Folder Cleanup\n";
my $folders = Vim::find_entity_views( view_type => 'Folder');
foreach my $folder (@$folders) {
       if (&Vcenter::check_if_empty_folder($folder->name)) {
                print "Deleting folder: ". $folder->name . "\n";
		&Vcenter::delete_folder($folder->name);
        }
}
print "Switch Cleanup\n";
my $switchs = Vim::find_entity_views( view_type=> 'DistributedVirtualSwitch');
foreach my $switch (@$switchs) {
	if (&Vcenter::check_if_empty_switch($switch->name)) {
                print "Deleting portgroup: ". $switch->name . "\n";
                &Vcenter::remove_switch($switch->name);
        }
}
# Disconnect from the server
Util::disconnect();
# To mitigate SSL warnings by default
BEGIN {
	$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
}
