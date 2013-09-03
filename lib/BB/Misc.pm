package Misc;

use strict;
use warnings;

BEGIN {
    use Exporter;
    our @ISA    = qw( Exporter );
    our @EXPORT = qw( );
}

sub array_longest($) {
    my ($array) = @_;
    &Log::debug("Starting Misc::array_longest sub");
    my $max = -1;
    for (@$array) {
        if ( length > $max ) {
            $max = length;
        }
    }
    &Log::debug("Longest element is $max");
    return $max;
}

sub random_3digit {
    &Log::debug("Starting Misc::random_3digit sub");
    return int( rand(999) );
}

sub generate_mac {
    my ($username) = @_;
    &Log::debug("Starting Misc::generate_mac sub, username=>'$username'");
    my $mac_base = &Support::get_key_value( 'agents', $username, 'mac' );
    &Log::debug("mac_base for $username=>'$mac_base'");
    my $mac = join ':', map { sprintf( "%02X", int rand(256) ) } ( 1 .. 3 );
    &Log::debug("Finished Misc::generate_mac sub, mac=>'$mac_base$mac'");
    return "$mac_base$mac";
}

sub generate_uniq_mac {
    &Log::debug("Starting Misc::generate_uniq_mac sub");
    my $mac = &generate_mac( Opts::get_option('username') );
    while ( &mac_compare($mac) ) {
        &Log::debug("Generationing new mac and testing");
        $mac = &generate_mac( Opts::get_option('username') );
    }
    &Log::debug("Mac is uniq, mac=>'$mac'");
    return $mac;
}

sub generate_macs {
    my ($count) = @_;
    &Log::debug("Starting Misc::generate_macs sub, count=>'$count'");
    my @mac = ();
    while ( @mac != $count ) {
        if ( @mac == 0 ) {
            &Log::debug("First mac needs to be generated");
            push( @mac, &Misc::generate_uniq_mac );
        }
        else {
            &Log::debug("Need to increment last mac");
            my $last = $mac[-1];
            my $new_mac;
            eval { $new_mac = &Misc::increment_mac($last); };
            if ($@) {
                &Log::debug(
                    "Increment is not possible, need to regenerate all macs");
                @mac = ();
            }
            else {
                &Log::debug("Need to investigate if mac is already used");
                if ( !&Misc::mac_compare($new_mac) ) {
                    &Log::debug("Pushing to array the mac=>'$new_mac'");
                    push( @mac, $new_mac );
                }
            }
        }
    }
    &Log::debug("Returning mac array");
    return @mac;
}

sub mac_compare {
    my ($mac) = @_;
    &Log::debug("Starting Misc::mac_compare sub, mac=>'$mac'");
    my $vm_view = Vim::find_entity_views(
        view_type  => 'VirtualMachine',
        properties => [ 'config.hardware.device', 'summary.config.name' ]
    );
    foreach (@$vm_view) {
        my $vm_name = $_->get_property('summary.config.name');
        my $devices = $_->get_property('config.hardware.device');
        foreach (@$devices) {
            if ( $_->isa("VirtualEthernetCard") ) {
                if ( $mac eq $_->macAddress ) {
                    &Log::info("Found VM with same MAC, name=>'$vm_name'");
                    return 1;
                }
            }
        }
    }
    &Log::info("No VM found with same mac");
    return 0;
}

# increment 1 on the last 3 bytes of the MAC. if overflow occurrs, then throw error
sub increment_mac($) {
    my ($mac) = @_;
    &Log::debug("Starting Misc::increment_mac, mac=>'$mac'");
    ( my $mac_hex = $mac ) =~ s/://g;
    my ( $mac_hi, $mac_lo ) = unpack( "nN", pack( 'H*', $mac_hex ) );
    if ( $mac_lo == 0x00FFFFFF ) {
        &Log::warning("Mac addressed reached end of pool");
        Entity::Mac->throw(
            error => "Mac addressed reached end of pool",
            mac   => $mac
        );
    }
    else {
        ++$mac_lo;
    }
    $mac_hex = sprintf( "%04X%08X", $mac_hi, $mac_lo );
    my $new_mac = join( ':', $mac_hex =~ /../sg );
    &Log::debug("Incrementd mac, mac=>'$new_mac'");
    return $new_mac;
}

sub vmname_splitter($) {
    my ($vmname) = @_;
    my %return = ();
    &Log::debug("Starting Misc::vmname_splitter sub, vmname=>'$vmname'");
    my ( $ticket, $username, $template, $uniq ) =
      $vmname =~ /^([^-]*)-([^-]*)-([^-]*)-(\d{1,3})$/;
    if ( defined($template)
        && $template =~ /^([^_]*)_([^_]*)_([^_]*)_([^_]*)_([^_]*)$/ )
    {
        %return = (
            ticket   => $ticket,
            username => $username,
            uniq     => $uniq,
            family   => $1,
            version  => $2,
            lang     => $3,
            arch     => $4,
            type     => $5
        );
    }
    elsif ( defined($template) && $template =~ /^([^_]*)_([^_]*)$/ ) {
        %return = (
            ticket   => $ticket,
            username => $username,
            uniq     => $uniq,
            family   => $1,
            version  => $2,
            lang     => 'en',
            arch     => 'x64',
            type     => 'xcb'
        );
    }
    else {
        &Log::warning("vmname is not standard. Returning unknown");
        %return = (
            ticket   => 'unknown',
            username => 'unknown',
            uniq     => 'unknown',
            family   => 'unknown',
            version  => 'unknown',
            lang     => 'unknown',
            arch     => 'unknown',
            type     => 'unknown'
        );
    }
    return \%return;
}

sub increment_disk_name($) {
    my ($name) = @_;
    &Log::debug("Starting Misc::increment_disk_name sub, name=>'$name'");
    my ( $pre, $num, $post );
    if ( $name =~ /(.*)_(\d+)(\.vmdk)/ ) {
        ( $pre, $num, $post ) = ( $1, $2, $3 );
        &Log::debug("disk has already been incremented, incrementing again");
        $num++;
        if ( $num == 7 ) {
            &Log::warning("We have reached the controller Id need to step one");
            $num++;
        }
        elsif ( $num > 15 ) {
            Entity::NumException->throw(
                error  => 'Cannot increment further. Last disk used',
                entity => $name,
                count  => '15'
            );
        }
    }
    else {
        &Log::debug("This will be first increment to disk name");
        ( $pre, $post ) = $name =~ /(.*)(\.vmdk)/;
        $num = 1;
    }
    &Log::debug("disk name has been incremented=>'${pre}_$num$post'");
    return "${pre}_$num$post";
}

sub filename_splitter($) {
    my ($filename) = @_;
    &Log::debug("Starting Misc::filename_splitter sub, filename=>'$filename'");
    my ( $datas, $folder, $image ) =
      $filename =~ qr@^\s*\[([^\]]*)\]\s*(.*)/([^/]*)$@;
    if ( !defined($datas) ) {
        Vcenter::Path->throw(
            error => 'Could not split filename, not according to regex',
            path  => $filename
        );
    }
    &Log::debug(
"Finished Misc::filename_splitter sub, datastore=>'$datas', folder=>'$folder', image=>'$image'"
    );
    return [ $datas, $folder, $image ];
}

sub generate_vmname($$$) {
    my ( $ticket, $username, $os_temp ) = @_;
    &Log::debug(
"Starting Misc::generate_vmname sub, ticket=>'$ticket', username=>'$username', os_temp=>'$os_temp'"
    );
    return $ticket . "-" . $username . "-" . $os_temp . "-" . &random_3digit;
}

sub uniq_vmname($) {
    my ( $ticket, $username, $os_temp ) = @_;
    &Log::debug(
"Starting Misc::uniq_vmname sub, ticket=>'$ticket', username=>'$username', os_temp=>'$os_temp'"
    );
    my $vmname = &generate_vmname( $ticket, $username, $os_temp );
    while ( &VCenter::exists_entity( $vmname, 'VirtualMachine' ) ) {
        &Log::debug("Generated name not uniq, regenerating");
        $vmname = &generate_vmname( $ticket, $username, $os_temp );
    }
    return $vmname;
}

1
__END__