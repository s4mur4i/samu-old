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
    my $mac = join ':', map { sprintf("%02X",int rand(256)) } (1..3);
    &Log::debug("Finished Misc::generate_mac sub, mac=>'$mac_base$mac'");
    return "$mac_base$mac";
}


# increment 1 on the last 3 bytes of the MAC. if overflow occurrs, then throw error
sub increment_mac($) {
    my ( $mac ) = @_;
    &Log::debug("Starting Misc::increment_mac, mac=>'$mac'");
    ( my $mac_hex = $mac ) =~ s/://g;
    my ( $mac_hi, $mac_lo ) = unpack( "nN", pack( 'H*', $mac_hex ) );
    if ( $mac_lo & 0x00FFFFFF == 0x00FFFFFF ) {
#error
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
    my %return = ();
    &Log::debug("Starting Misc::vmname_splitter sub, vmname=>'$vmname'");
    my ( $ticket, $username, $template, $uniq ) = $vmname =~ /^([^-]*)-([^-]*)-([^-]*)-(\d{1,3})$/;
    if ( defined($template) && $template =~ /^([^_]*)_([^_]*)_([^_]*)_([^_]*)_([^_]*)$/ ) {
        %return = ( ticket => $ticket, username => $username, uniq => $uniq, family => $1, version => $2, lang => $3, arch => $4, type => $5 );
    } elsif ( defined($template) && $template =~ /^([^_]*)_([^_]*)$/ ) {
        %return = ( ticket => $ticket, username => $username, uniq => $uniq, family => $1, version => $2, lang => 'en', arch => 'x64', type => 'xcb' );
    } else {
        &Log::warning("vmname is not standard. Returning unknown");
        %return = ( ticket => 'unknown', username => 'unknown', uniq => 'unknown', family => 'unknown', version => 'unknown', lang => 'unknown', arch => 'unknown', type => 'unknown' );
    }
    return \%return;
}


1
__END__
