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
Util::trace( 0, "Resouce Pool cleanup\n" );
eval {
my $rp_pools = Vim::find_entity_views( view_type => 'ResourcePool', properties => [ 'name' ] );
foreach my $pool (@$rp_pools) {
	if (&Vcenter::check_if_empty_resource_pool($pool->name)) {
		Util::trace( 0, "Deleting resource pool:". $pool->name ."\n" );
		&Vcenter::delete_resource_pool($pool->name);
	}
}
Util::trace( 0, "Folder Cleanup\n" );
my $folders = Vim::find_entity_views( view_type => 'Folder', properties => [ 'name' ] );
foreach my $folder (@$folders) {
       if (&Vcenter::check_if_empty_folder($folder->name)) {
                Util::trace( 0, "Deleting folder: ". $folder->name . "\n" );
		&Vcenter::delete_folder($folder->name);
        }
}
Util::trace( 0, "Switch Cleanup\n" );
my $switchs = Vim::find_entity_views( view_type=> 'DistributedVirtualSwitch', properties => [ 'name' ] );
foreach my $switch (@$switchs) {
	if (&Vcenter::check_if_empty_switch($switch->name)) {
                Util::trace( 0, "Deleting portgroup: ". $switch->name . "\n" );
                &Vcenter::remove_switch($switch->name);
        }
}
};
if ($@) { &Error::catch_ex( $@ ); }
# Disconnect from the server
Util::disconnect();
# To mitigate SSL warnings by default
BEGIN {
	$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
}
