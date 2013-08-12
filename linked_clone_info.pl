#!/usr/bin/perl
### Find machines linked to the last snapshot of this machine.
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use SDK::Support;
use SDK::GuestInternal;
use VMware::VIRuntime;
use Data::Dumper;

my %opts = (
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
my $url = Opts::get_option('url');
Util::connect( $url, $username, $password );

## Get machine view
my $machine_view = Vim::find_entity_view(view_type=>'VirtualMachine', filter => { name => Opts::get_option('vmname')});
my $snapshot_view = $machine_view->snapshot->rootSnapshotList;
if (defined($snapshot_view->[0]->{'childSnapshotList'})) {
	$snapshot_view = &GuestInternal::find_root_snapshot( $snapshot_view->[0]->{'childSnapshotList'} );
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
