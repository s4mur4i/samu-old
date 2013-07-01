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
        name => {
                type => "=s",
                help => "Name of switch to remove",
                required => 1,
        },
);
Opts::add_options(%opts);
Opts::parse();
Opts::validate();
my $username = Opts::get_option('username');
my $password = Opts::get_option('password');
my $url = Opts::get_option('url');
my $name = Opts::get_option('name');
Util::connect( $url, $username, $password );
my $switch = Vim::find_entity_view( view_type => 'DistributedVirtualSwitch', filter=>{ name=>$name});
if (defined($switch)) {
	my $portgroups = $switch->summary->portgroupName;
	foreach (@$portgroups) {
		my $portgroup = Vim::find_entity_view( view_type => 'DistributedVirtualPortgroup', filter => {name => $_});
		if (defined($portgroup->vm)) {
			print "Switch has child vm-s\n";
			my $vms = $portgroup->vm;
			foreach (@$vms) {
				my $portgroup_key = $portgroup->key;
				my $vm = Vim::get_view( mo_ref => $_);
					my $count=0;
					foreach ( @{$vm->config->hardware->device}) {
						my $interface = $_;
						if ( $interface->isa('VirtualE1000')) {
							print Dumper($interface);
							if ( exists $interface->backing->{'port'} && $interface->backing->port->portgroupKey eq $portgroup_key) {
								my $network = Vim::find_entity_view( view_type=> 'Network',filter => { 'name' => "VLAN21" });
								&GuestManagement::change_network_interface($vm->name,$count,$network->name);
							}
							$count++;
					}
				}
			}
		}
	}
	&GuestManagement::remove_switch($name);
} else {
	print "No switch under name: $name\n";
}
# Disconnect from the server
Util::disconnect();
# To mitigate SSL warnings by default
BEGIN {
	$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
}
