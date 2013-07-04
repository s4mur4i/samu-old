package Misc;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin";
use SDK::Vcenter;
BEGIN {
        use Exporter;
        our @ISA = qw(Exporter);
        our @EXPORT = qw( &test &random_3digit &generate_mac &generate_uniq_mac &increment_mac &vmname_splitter &generate_vmname );
        our @EXPORT_OK = qw( &test &random_3digit &generate_mac &generate_uniq_mac &increment_mac &vmname_splitter &generate_vmname );
}

## Returns a 3 digit random number
## Parameters:
##
## Returns:
##  random: 3 digit random number
sub random_3digit {
        my $random;
        $random = int(rand(999));
        return $random;
}

## Generates a new mac according to agents pool
## Parameters:
##
## Returns:
##  mac: new mac address format: xx:xx:xx:xx:xx:xx

sub generate_mac {
        my $username = Opts::get_option('username');
        my $mac_base;
        if ( !defined($Support::agents_hash{$username})) {
                $mac_base = "02:01:00:";
        } else {
                $mac_base = $Support::agents_hash{$username}{'mac'};
        }
        my @chars = ( "A" .. "F", "0" .. "9");
        my $mac = join("", @chars[ map { rand @chars } ( 1 .. 6 ) ]);
        $mac =~ s/(..)/$1:/g;
        chop $mac;
        return "$mac_base$mac";
}

## Generates a new mac and test if uniq
## Parameters:
##
## Returns:
##  mac: new mac address format: xx:xx:xx:xx:xx:xx

sub generate_uniq_mac {
        my $mac = &generate_mac;
        print "Generated mac address: $mac\n";
        while ( &Vcenter::mac_compare($mac) ) {
                print "Found duplicate mac, need to regenerate\n";
                $mac = &generate_mac;
                print "New generated mac address: $mac\n";
        }
        return $mac;
}

## Increment mac address by 1
## Parameters:
##  mac: mac address to increment format: xx:xx:xx:xx:xx:xx
## Returns:
##  mac: incremented mac address format: xx:xx:xx:xx:xx:xx

sub increment_mac {
	my ($mac) = @_;
	print "Need to increment: $mac\n";
	( my $mac_hex= $mac ) =~ s/://g;
	my ( $mac_hi, $mac_lo ) = unpack("nN", pack('H*', $mac_hex));
	if ( $mac_lo == 0xFFFFFFFF ) {
		$mac_hi = ( $mac_hi + 1 ) & 0xFFFF;
		$mac_lo = 0;
	} else {
		++$mac_lo;
	}
	$mac_hex = sprintf("%04X%08X", $mac_hi, $mac_lo);
	my $new_mac = join( ':', $mac_hex =~ /../sg );
	print "Incremented mac address: $new_mac\n";
	while ( &Vcenter::mac_compare($new_mac) ) {
                print "Found duplicate mac=>$new_mac, need to regenerate\n";
                $new_mac = &increment_mac($new_mac);
                print "New generated mac address: $new_mac\n";
        }
	return $new_mac;
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
	my ($vmname) = @_;
	if ( $vmname !~ /^([^-]*)-([^-]*)-([^-]*)-(\d{1,3})$/ ) {
		print "Cannot match standard regex\n";
		return ("unknown", "unknown", "unknown", "unknown", "unknown", "unknown", "unknown", "unknown");
	}
	my ( $ticket, $username, $template, $uniq) = $vmname =~ /^([^-]*)-([^-]*)-([^-]*)-(\d{3})$/ ;
	my ( $family, $version, $lang, $arch, $type );
	if ( $template =~ /^[^_]*_[^_]*$/ ) {
		print "XCB product.\n";
		( $family, $version ) = $template =~ /^([^_]*)_([^_]*)$/;
		$lang = "en";
		$arch = "x64";
		$type = "xcb";
	} else {
		( $family, $version, $lang, $arch, $type ) = $template =~ /^([^_]*)_([^_]*)_([^_]*)_([^_]*)_([^_]*)$/;
	}
	print "vmname_splitter return: ticket => $ticket, username => $username, family => $family, version => $version, lang => $lang, arch => $arch, type => $type , uniq => $uniq\n";
	return ($ticket, $username, $family, $version, $lang, $arch, $type , $uniq);
}

sub generate_vmname {
	my ($ticket,$username,$os_temp) = @_;
	my $vmname = $ticket . "-" . $username . "-" . $os_temp . "-" . &random_3digit;
	while (&Vcenter::exists_vm($vmname)) {
		$vmname = $ticket . "-" . $username . "-" . $os_temp . "-" . &random_3digit;
	}
	return $vmname;
}

## Functionality test sub
sub test() {
        print "Misc module test sub\n";
}

#### We need to end with success
1
