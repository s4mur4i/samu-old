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

## Returns a 3 digit random number
## Parameters:
##
## Returns:
##  random: 3 digit random number
sub random_3digit {
	Util::trace( 4, "Started Misc::random_3digit sub\n" );
	my $random;
	$random = int( rand( 999 ) );
	Util::trace( 4, "Finished Misc::random_3digit sub return=>'$random'\n" );
	return $random;
}

## Generates a new mac according to agents pool
## Parameters:
##
## Returns:
##  mac: new mac address format: xx:xx:xx:xx:xx:xx

sub generate_mac {
	my $username = Opts::get_option( 'username' );
	Util::trace( 4, "Starting Misc::generate_mac sub, username=>'$username'\n" );
	my $mac_base;
	if ( !defined( $Support::agents_hash{$username} ) ) {
		$mac_base = "02:01:00:";
	} else {
		$mac_base = $Support::agents_hash{$username}{'mac'};
	}
	my @chars = ( "A".."F", "0".."9" );
	my $mac = join( "", @chars[ map { rand @chars } ( 1..6 ) ] );
	$mac =~ s/(..)/$1:/g;
	chop $mac;
	Util::trace( 4, "Finished Misc::generate_mac sub, mac=>'$mac_base$mac'\n" );
	return "$mac_base$mac";
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

## Increment mac address by 1
## Parameters:
##  mac: mac address to increment format: xx:xx:xx:xx:xx:xx
## Returns:
##  mac: incremented mac address format: xx:xx:xx:xx:xx:xx

sub increment_mac {
	my ( $mac ) = @_;
	Util::trace( 4, "Starting Misc::increment_mac sub, mac=>'$mac'\n" );
	( my $mac_hex = $mac ) =~ s/://g;
	my ( $mac_hi, $mac_lo ) = unpack( "nN", pack( 'H*', $mac_hex ) );
	if ( $mac_lo == 0xFFFFFFFF ) {
		$mac_hi = ( $mac_hi + 1 ) & 0xFFFF;
		$mac_lo = 0;
	} else {
		++$mac_lo;
	}
	$mac_hex = sprintf( "%04X%08X", $mac_hi, $mac_lo );
	my $new_mac = join( ':', $mac_hex =~ /../sg );
	Util::trace( 3, "Incremented mac address=>'$new_mac'\n" );
	while ( &Vcenter::mac_compare( $new_mac ) ) {
		Util::trace( 3, "Found duplicate mac =>'$new_mac', need to regenerate\n" );
		$new_mac = &increment_mac( $new_mac );
		Util::trace( 3, "New generated mac address=>'$new_mac'\n" );
	}
	Util::trace( 4, "Finished Misc::increment_mac sub, incremented_mac=>'$new_mac'\n" );
	return $new_mac;
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

## Splits default provisioned name to variables
## Parameters:
##  vmname: vmname to split
## Returns:
##  ticket: ticket number vm is attached to
##  username: User who provisioned machine
##  family: OS family of template
##  version: OS version of template
##  lang: OS language of template
##  arch: x64 or x86
##  type: Which version of OS
##  uniq: Uniq number attached to machine

sub vmname_splitter {
	my ( $vmname ) = @_;
	Util::trace( 4, "Starting Misc::vmname_splitter sub, vmname=>'$vmname'\n" );
	if ( $vmname !~ /^([^-]*)-([^-]*)-([^-]*)-(\d{1,3})$/ ) {
		Util::trace( 4, "Not standard name, returning unknown\n" );
		return ( "unknown", "unknown", "unknown", "unknown", "unknown", "unknown", "unknown", "unknown" );
	}
	my ( $ticket, $username, $template, $uniq ) = $vmname =~ /^([^-]*)-([^-]*)-([^-]*)-(\d{1,3})$/ ;
	my ( $family, $version, $lang, $arch, $type );
	if ( $template =~ /^[^_]*_[^_]*$/ ) {
		( $family, $version ) = $template =~ /^([^_]*)_([^_]*)$/;
		$lang = "en";
		$arch = "x64";
		$type = "xcb";
	} else {
		( $family, $version, $lang, $arch, $type ) = $template =~ /^([^_]*)_([^_]*)_([^_]*)_([^_]*)_([^_]*)$/;
	}
	Util::trace( 4, "Finished Misc::vmname_splitter sub, ticket=>'$ticket', username=>'$username', family=>'$family', version=>'$version', lang=>'$lang', arch=>'$arch', type=>'$type', uniq=>'$uniq'\n" );
	return ( $ticket, $username, $family, $version, $lang, $arch, $type , $uniq );
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
