package Misc;

use strict;
use warnings;
use BB::Error;
use BB::Log;
use BB::Support;

BEGIN {
    use Exporter;
    our @ISA = qw( Exporter );
    our @EXPORT = qw( &array_longest &random_3digit &generate_mac &increment_mac &vmname_splitter &increment_disk_name &filename_splitter &generate_vmname );
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
        &Log::warning("Mac addressed reached end of pool");
        Entity::Mac->throw( error => "Mac addressed reached end of pool", mac => $mac );
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

sub increment_disk_name($) {
    my ( $name ) = @_;
    &Log::debug("Starting Misc::increment_disk_name sub, name=>'$name'");
    my ( $pre, $num, $post );
    if ( $name =~ /(.*)_(\d+)(\.vmdk)/ ) {
        ( $pre, $num, $post ) = ($1, $2, $3);
        &Log::debug("disk has already been incremented, incrementing again");
        $num++;
        if ( $num == 7 ) {
            &Log::warning("We have reached the controller Id need to step one");
            $num++;
        }  elsif ( $num > 15 ) {
            Entity::NumException->throw( error => 'Cannot increment further. Last disk used', entity => $name, count => '15' );
        }
    } else {
        &Log::debug("This will be first increment to disk name");
        ( $pre, $post ) = $name =~ /(.*)(\.vmdk)/;
        $num =1;
    }
    &Log::debug("disk name has been incremented=>'${pre}_$num$post'");
    return "${pre}_$num$post";
}

sub filename_splitter {
    my ( $filename ) = @_;
    &Log::debug("Starting Misc::filename_splitter sub, filename=>'$filename'");
    my ( $datas, $folder, $image ) = $filename =~ qr@^\s*\[([^\]]*)\]\s*(.*)/([^/]*)$@;
    if ( !defined($datas) ) {
        Vcenter::Path->throw( error => 'Could not split filename, not according to regex', path => $filename );
    }
    &Log::debug("Finished Misc::filename_splitter sub, datastore=>'$datas', folder=>'$folder', image=>'$image'");
    return [ $datas, $folder, $image ];
}

sub generate_vmname {
    my ( $ticket, $username, $os_temp ) = @_;
    &Log::debug("Starting Misc::generate_vmname sub, ticket=>'$ticket', username=>'$username', os_temp=>'$os_temp'");
    return $ticket . "-" . $username . "-" . $os_temp . "-" . &random_3digit;
}

1
__END__
