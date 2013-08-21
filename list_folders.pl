#!/usr/bin/perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
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
my ($datacenter_views, $vmFolder_view, $indent);
$indent = 0;
$datacenter_views = Vim::find_entity_views( view_type => 'Datacenter', properties => ["name", "vmFolder"]);
foreach ( @{$datacenter_views} )
{
	Util::trace( 0, "Datacenter: " . $_->name . "\n" );
	TraverseFolder($_->vmFolder, $indent);
}

sub TraverseFolder {
	my ($entity_moref, $index) = @_;
	my ($num_entities, $entity_view, $child_view, $i, $mo);
	$index += 2;
	$entity_view = Vim::get_view( mo_ref => $entity_moref, properties => ['name', 'childEntity']);
	$num_entities = defined($entity_view->childEntity) ? @{$entity_view->childEntity} : 0;
	if ( $num_entities > 0 ) {
		foreach $mo ( @{$entity_view->childEntity} ) {
			$child_view = Vim::get_view( mo_ref => $mo, properties => ['name']);
			if ( $child_view->isa("VirtualMachine") ) {
				Util::trace( 0, " " x $index . "Virtual Machine: " . $child_view->name . "\n" );
			}

			if ( $child_view->isa("Folder") ) {
				print " " x $index . "Folder: " . $child_view->name . "\n";
				$child_view = Vim::get_view( mo_ref => $mo, properties => ['name', 'childEntity'] );
				TraverseFolder($mo, $index);
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
