package Misc;

use strict;
use warnings;
use BB::Error;
use BB::Log;
use BB::Support;

BEGIN {
    use Exporter;
    our @ISA = qw( Exporter );
    our @EXPORT = qw( &array_longest &random_3digit &generate_mac );
}

sub array_longest {
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

sub generate_mac {
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


1
__END__
