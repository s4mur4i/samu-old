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

sub increment_disk_name {
	my ( $name ) = @_;
	Util::trace( 4, "Starting Misc::increment_disk_name sub, name=>'$name'\n" );
	my ( $pre, $num, $post );
	if ( $name =~ /(.*)_(\d+)(\.vmdk)/ ) {
		( $pre, $num, $post ) = $name =~ /(.*)_(\d+)(\.vmdk)/;
		Util::trace( 5, "Incremented Num:'" . $num . "'\n" );
		$num++;
		if ( $num == 7 ) {
			$num++;
		}  elsif ( $num > 15 ) {
			SDK::Error::Entity::NumException->throw( error => 'Cannot increment further. Last disk used', entity => $name, count => '15' );
		}
	} else {
		Util::trace( 5, "No num, need to do first increment\n" );
		( $pre, $post ) = $name =~ /(.*)(\.vmdk)/;
		$num =1;
	}
	Util::trace( 4, "Finished Misc::increment_disk_name sub, incremented_name=>'${pre}_$num$post'\n" );
	return "${pre}_$num$post";
}
sub filename_splitter {
	my ( $filename ) = @_;
	Util::trace( 4, "Starting Misc::filename_splitter sub, filename=>'$filename'\n" );
	my ( $datas, $folder, $image ) = $filename =~ qr@^\s*\[([^\]]*)\]\s*(.*)/([^/]*)$@;
	Util::trace( 4, "Finished Misc::filename_splitter sub, datastore=>'$datas', folder=>'$folder', image=>'$image'\n" );
	return ( $datas, $folder, $image );
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
