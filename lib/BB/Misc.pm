package Misc;

use strict;
use warnings;
use BB::Error;
use BB::Log;
use BB::Support;

BEGIN {
    use Exporter;
    our @ISA = qw( Exporter );
    our @EXPORT = qw( &array_longest &random_3digit &generate_mac &increment_mac &vmname_splitter );
}

sub array_longest($) {
    my ( $array ) = @_;
    &Log::debug("Starting Misc::array_longest sub");
    my $max = -1;
    for ( @$array ) {
        if ( length > $max ) {
            $max = length;
        }
    }
    &Log::debug("Longest element is $max");
    return $max;
}

sub random_3digit {
    &Log::debug("Starting Misc::random_3digit sub");
    return int( rand( 999 ) );
}

sub generate_mac($) {
    my ( $username ) = @_;
    &Log::debug("Starting Misc::generate_mac sub, username=>'$username'");
    my $mac_base = &Support::get_key_value('agents',$username,'mac');
    &Log::debug("mac_base for $username=>'$mac_base'");
    my @chars = ( "A".."F", "0".."9" );
    my $mac = join( "", @chars[ map { rand @chars } ( 1..6 ) ] );
    $mac =~ s/(..)/$1:/g;
    chop $mac;
    &Log::debug("Finished Misc::generate_mac sub, mac=>'$mac_base$mac'");
    return "$mac_base$mac";
}

sub increment_mac($) {
    my ( $mac ) = @_;
    &Log::debug("Starting Misc::increment_mac, mac=>'$mac'");
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
    &Log::debug("Incrementd mac, mac=>'$new_mac'");
    return $new_mac;
}

sub vmname_splitter($) {
    my ( $vmname ) = @_;
    &Log::debug("Starting Misc::vmname_splitter sub, vmname=>'$vmname'");
    if ( $vmname !~ /^([^-]*)-([^-]*)-([^-]*)-(\d{1,3})$/ ) {
        &Log::warning("vmname is not standard. Returning unknown");
        return ( "unknown", "unknown", "unknown", "unknown", "unknown", "unknown", "unknown", "unknown" );
    }
    my ( $ticket, $username, $template, $uniq ) = $vmname =~ /^([^-]*)-([^-]*)-([^-]*)-(\d{1,3})$/ ;
    &Log::debug("ticket=>'$ticket',username=>'$username',uniq=>'$uniq'");
    my ( $family, $version, $lang, $arch, $type );
    if ( $template =~ /^[^_]*_[^_]*$/ ) {
        ( $family, $version ) = $template =~ /^([^_]*)_([^_]*)$/;
        $lang = "en";
        $arch = "x64";
        $type = "xcb";
    } else {
        ( $family, $version, $lang, $arch, $type ) = $template =~ /^([^_]*)_([^_]*)_([^_]*)_([^_]*)_([^_]*)$/;
    }
    &Log::debug("family=>'$family',version=>'$version',lang=>'$lang',arch=>'$arch',type=>'$type'");
    return ( $ticket, $username, $family, $version, $lang, $arch, $type , $uniq );
}


1
__END__
