#!/usr/bin/perl
### Find machines linked to the last snapshot of this machine.
use strict;
use warnings;
#use diagnostics;
use FindBin;
use lib "$FindBin::Bin/lib";
use lib '/usr/lib/vmware-vcli/apps';
use Support;
use VMware::VICommon;
use VMware::VIRuntime;
#use VMware::VILib;
#use AppUtil::VMUtil;
use Data::Dumper;
#use Switch;

sub find_root_snapshot {
	my ($snapshot) = @_;
	if ( defined($snapshot->[0]->{'childSnapshotList'})) {
		find_root_snapshot($snapshot->[0]->{'childSnapshotList'});
	} else {
	return $snapshot;
	}
}

my %opts = (
username => {
type => "=s",
variable => "VI_USERNAME",
help => "Username to ESX",
required => 0,
},
password => {
type => "=s",
variable => "VI_PASSWORD",
help => "Password to ESX",
required => 0,
},
server => {
type => "=s",
variable => "VI_SERVER",
help => "ESX hostname or IP address",
default => "vcenter.ittest.balabit",
required => 0,
},
protocol => {
type => "=s",
variable => "VI_PROTOCOL",
help => "http or https, that is the question",
default => "https",
required => 0,
},
portnumber => {
type => "=i",
variable => "VI_PROTOCOL",
help => "ESX port for connection",
default => "443",
required => 0,
},
url => {
type => "=s",
variable => "VI_URL",
help => "URL for ESX",
required => 0,
},
datacenter => {
type => "=s",
help => "Datacenter",
default => "support",
required => 0,
},
vmname => {
type => "=s",
help => "Get list of linked VM-s to the machine",
required => 1,
},
);
Opts::add_options(%opts);
Opts::parse();
Opts::validate();
my $username = Opts::get_option('username');
my $password = Opts::get_option('password');
my $datacenter = Opts::get_option('datacenter');
my $url = Opts::get_option('url');
Util::connect( $url, $username, $password );

## Get machine view
my $machine_view = Vim::find_entity_view(view_type=>'VirtualMachine', filter => { name => Opts::get_option('vmname')});
my $snapshot_view = $machine_view->snapshot->rootSnapshotList;
if (defined($snapshot_view->[0]->{'childSnapshotList'})) {
	$snapshot_view = find_root_snapshot( $snapshot_view->[0]->{'childSnapshotList'} );
}
$snapshot_view = Vim::get_view (mo_ref =>$snapshot_view->[0]->{'snapshot'});
my $devices = $snapshot_view->{'config'}->{'hardware'}->{'device'};
my $disk;
foreach my $device (@$devices) {
	#print Dumper($device);
	if ( defined($device->{'backing'}->{'fileName'})) {
		$disk = $device->{'backing'}->{'fileName'};
		last;
	}
}
## This is the disk attached to the last snapshot
print "my disk is $disk\n";
## https://vcenter.ittest.balabit/mob/?moid=vm-883&doPath=config.hardware.device[2000].backing
my $machine_views = Vim::find_entity_views(view_type => 'VirtualMachine', properties => ['layout.disk', 'name']);
foreach (@$machine_views) {
	my $machine_view = $_;
	my $disks = $machine_view->get_property('layout.disk');
	foreach my $vdisk (@$disks) {
		foreach my $diskfile ( @{$vdisk->{'diskFile'}}) {
			if ( $diskfile eq $disk) {
				print "Machine name: " . $machine_view->get_property('name') . "\n";
			}
		}
	}
}

# Disconnect from the server
Util::disconnect();
# To mitigate SSL warnings by default
BEGIN {
$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
}
