package Misc;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin";
use SDK::Vcenter;
use URI::Escape;
BEGIN {
	use Exporter;
	our @ISA = qw( Exporter );
	our @EXPORT = qw( &test &random_3digit &generate_mac &generate_uniq_mac &increment_mac &vmname_splitter &generate_vmname &increment_disk_name &path_to_url &filename_splitter );
}

## Generates a new mac and test if uniq
## Parameters:
##
## Returns:
##  mac: new mac address format: xx:xx:xx:xx:xx:xx

sub generate_uniq_mac {
	Util::trace( 4, "Starting Misc::generate_uniq_mac sub\n" );
	my $mac = &generate_mac;
	Util::trace( 1, "Generated mac address, mac=>'$mac'\n" );
	while ( &Vcenter::mac_compare( $mac ) ) {
		Util::trace( 1, "Found duplicate mac, need to regenerate\n" );
		$mac = &generate_mac;
		Util::trace( 1, "New generated mac address=>'$mac'\n" );
	}
	Util::trace( 4, "Finished Misc::generate_uniq_mac sub, mac=>'$mac'\n" );
	return $mac;
}

sub path_to_url {
	my ( $path ) = @_;
	Util::trace( 4, "Starting Misc::path_to_url sub, path=>'$path'\n" );
	my $url_base ="https://vcenter.ittest.balabit/folder/";
	my ( $datastore, $path_url ) = $path =~ /^\[([^\]]*)\]\s*(.*)$/;
	my $return = $url_base . $path_url ."?dcPath =Support&dsName =" .$datastore;
	$return =~ s/-/%2d/g;
	$return =~ s/\./%2e/g;
	Util::trace( 4, "Finished Misc::path_to_url sub, url=>'$return'\n" );
	return $return;
}

sub generate_vmname {
	my ( $ticket, $username, $os_temp ) = @_;
	Util::trace( 4, "Starting Misc::generate_vmname sub, ticket=>'$ticket', username=>'$username', os_temp=>'$os_temp'\n" );
	my $vmname = $ticket . "-" . $username . "-" . $os_temp . "-" . &random_3digit;
	while ( &Vcenter::exists_vm( $vmname ) ) {
		$vmname = $ticket . "-" . $username . "-" . $os_temp . "-" . &random_3digit;
	}
	Util::trace( 4, "Finished Misc::generate_vmname sub, vmname=>'$vmname'\n" );
	return $vmname;
}

## Functionality test sub
sub test( ) {
	Util::trace( 4, "Starting Misc::test sub\n" );
	Util::trace( 0, "Misc module test sub\n" );
	Util::trace( 4, "Finished Misc::test sub" );
}

#### We need to end with success
1
