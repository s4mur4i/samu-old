package Misc;

use strict;
use warnings;

=pod

=head1 Misc.pm

Subroutines from BB/Misc.pm

=cut

BEGIN {
    use Exporter;
    our @ISA    = qw( Exporter );
    our @EXPORT = qw( );
}

=pod

=head2 array_longest

=head3 PURPOSE

Returns longest element length of an array

=head3 PARAMETERS

=over

=item array

Array ref to array

=back

=head3 RETURNS

Max length of longest element

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

=head3 SEE ALSO

=cut

sub array_longest {
    my ($array) = @_;
    &Log::debug("Starting Misc::array_longest sub");
    &Log::dumpobj("array", $array);
    my $max = -1;
    for (@$array) {
        if ( length > $max ) {
            $max = length;
        }
    }
    &Log::debug("Return=>'$max'");
    &Log::debug("Finishing Misc::array_longest sub");
    return $max;
}

=pod

=head2 random_3digit

=head3 PURPOSE

Returns a a random number between 1-999

=head3 PARAMETERS

=over

=back

=head3 RETURNS

A number between 1 and 999

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

=head3 SEE ALSO

=cut

sub random_3digit {
    &Log::debug("Starting Misc::random_3digit sub");
    my $ret = int( rand(999) );
    &Log::debug("Finishing Misc::random_3digit sub");
    &Log::debug("Return=>'$ret'");
    return $ret;
}

=pod

=head2 generate_mac

=head3 PURPOSE

Generates a mac from agents pool

=head3 PARAMETERS

=over

=item username

Username to take mac pool from

=back

=head3 RETURNS

A valid mac address

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

If user is unknown we should implement a fallback method
Also username should be check to mac it take from VMWare SDK options hash

=head3 SEE ALSO

=cut

sub generate_mac {
    my ($username) = @_;
    &Log::debug("Starting Misc::generate_mac sub");
    &Log::debug1("Opts are: username=>'$username'");
    my $mac_base = &Support::get_key_value( 'agents', $username, 'mac' );
    &Log::debug("mac_base for $username=>'$mac_base'");
    my $mac = join ':', map { sprintf( "%02X", int rand(256) ) } ( 1 .. 3 );
    &Log::debug("Finishing Misc::generate_mac sub");
    &Log::debug("Return=>'$mac_base$mac'");
    return "$mac_base$mac";
}

=pod

=head2 generate_uniq_mac

=head3 PURPOSE

Generates a uniq mac not found on the VCenter

=head3 PARAMETERS

=over

=back

=head3 RETURNS

A uniq mac

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

=head3 SEE ALSO

=cut

sub generate_uniq_mac {
    &Log::debug("Starting Misc::generate_uniq_mac sub");
    my $mac = &Misc::generate_mac( Opts::get_option('username') );
    while ( &Misc::mac_compare($mac) ) {
        &Log::debug("Generationing new mac and testing");
        $mac = &Misc::generate_mac( Opts::get_option('username') );
    }
    &Log::debug("Finishing Misc::generate_uniq_mac_sub");
    &Log::debug("Return=>'$mac'");
    return $mac;
}

=pod

=head2 generate_macs

=head3 PURPOSE

Generates the requested of number of mac addresses that follow each other as possible

=head3 PARAMETERS

=over

=item count

The number of mac addresses required

=back

=head3 RETURNS

Array ref of mac addresses

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

=head3 SEE ALSO

=cut

sub generate_macs {
    my ($count) = @_;
    &Log::debug("Starting Misc::generate_macs sub");
    &Log::debug1("Opts are: count=>'$count'");
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
    &Log::debug("Finishing Misc::generate_macs sub");
    &Log::dumpobj("macs", \@mac);
    return \@mac;
}

=pod

=head2 mac_compare

=head3 PURPOSE

Compares if mac is uniq on VCenter

=head3 PARAMETERS

=over

=item mac

Mac address to test if uniq

=back

=head3 RETURNS

True if mac found
False if mac is uniq

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

=head3 SEE ALSO

=cut

sub mac_compare {
    my ($mac) = @_;
    &Log::debug("Starting Misc::mac_compare sub");
    &Log::debug1("Opts are: mac=>'$mac'");
    my $vm_view = Vim::find_entity_views(
        view_type => 'VirtualMachine',
        properties =>
          [ 'config.hardware.device', 'summary.config.name', 'name' ]
    );
    foreach (@$vm_view) {
        &Log::debug( "Examining VM=>'" . $_->name . "'" );
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

=pod

=head2 increment_mac

=head3 PURPOSE

Increments one on the mac address

=head3 PARAMETERS

=over

=item mac

Mac address

=back

=head3 RETURNS

Incremented Mac address

=head3 DESCRIPTION

Increment 1 on the last 3 bytes of the MAC. if overflow occurrs, then throw error

=head3 THROWS

Entity::Mac if mac pool end reached

=head3 COMMENTS

=head3 SEE ALSO

=cut

sub increment_mac {
    my ($mac) = @_;
    &Log::debug("Starting Misc::increment_mac sub");
    &Log::debug("Opts are: mac=>'$mac'");
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
    if ( &Misc::mac_compare($new_mac) ) {
        &Log::info("Incrementing mac again");
        $new_mac = &Misc::increment_mac($new_mac);
    }
    &Log::debug("Return=>'$new_mac'");
    &Log::debug("Finishing Misc::increment_mac sub");
    return $new_mac;
}

=pod

=head2 vmname_splitter

=head3 PURPOSE

Virtual Machine name to split

=head3 PARAMETERS

=over

=item vmname

Name of virtual machine to split

=back

=head3 RETURNS

Hash with extracted information

=head3 DESCRIPTION

If standard is not recognised by regex than unknown is returned for all elements

=head3 THROWS

=head3 COMMENTS

=head3 SEE ALSO

=cut

sub vmname_splitter {
    my ($vmname) = @_;
    my %return = ();
    &Log::debug("Starting Misc::vmname_splitter sub");
    &Log::debug("Opts are: vmname=>'$vmname'");
    my ( $ticket, $username, $template, $uniq ) =
      $vmname =~ /^([^-]*)-([^-]*)-([^-]*)-(\d{1,3})$/;
    if ( defined($template)
        and $template =~ /^([^_]*)_([^_]*)_([^_]*)_([^_]*)_([^_]*)$/ )
    {
        &Log::info("Standard VM name detected");
        %return = (
            ticket   => $ticket,
            username => $username,
            uniq     => $uniq,
            family   => $1,
            version  => $2,
            lang     => $3,
            arch     => $4,
            type     => $5,
            template => $template,
        );
    }
    elsif ( defined($template) and $template =~ /^([^_]*)_([^_]*)$/ ) {
        &Log::info("XCB standard name detected");
        %return = (
            ticket   => $ticket,
            username => $username,
            uniq     => $uniq,
            family   => $1,
            version  => $2,
            lang     => 'en',
            arch     => 'x64',
            type     => 'xcb',
            template => $template,
        );
    }
    else {
        &Log::info("vmname is not standard. Returning unknown");
        %return = (
            ticket   => 'unknown',
            username => 'unknown',
            uniq     => 'unknown',
            family   => 'unknown',
            version  => 'unknown',
            lang     => 'unknown',
            arch     => 'unknown',
            type     => 'unknown',
            template => 'unknown',
        );
    }
    &Log::debug("Finishing Misc::vmname_splitter sub");
    &Log::loghash("Return hash", \%return);
    return \%return;
}

=pod

=head2 increment_disk_name

=head3 PURPOSE

Increments a datastore path for new disk creation

=head3 PARAMETERS

=over

=item name

Disk path to increment

=back

=head3 RETURNS

Incremented datastore name

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

test should be implemented if incremented disk name already exists on datastore

=head3 SEE ALSO

=cut

sub increment_disk_name {
    my ($name) = @_;
    &Log::debug("Starting Misc::increment_disk_name sub");
    &Log::debug1("Opts are: name=>'$name'");
    my ( $pre, $num, $post );
    if ( $name =~ /(.*)_(\d+)(\.vmdk)/ ) {
        ( $pre, $num, $post ) = ( $1, $2, $3 );
        &Log::debug("Disk has already been incremented, incrementing again");
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
    &Log::debug("Finishing Misc::increment_disk_name sub");
    &Log::debug("Return=>'${pre}_$num$post'");
    return "${pre}_$num$post";
}

=pod

=head2 filename_splitter

=head3 PURPOSE

Splits a datastore path to datastore folder and image string

=head3 PARAMETERS

=over

=item filename

Datastore path

=back

=head3 RETURNS

Array containing the split variables

=head3 DESCRIPTION

=head3 THROWS

Vcenter::Path if path is not a valid path

=head3 COMMENTS

=head3 SEE ALSO

=cut

sub filename_splitter {
    my ($filename) = @_;
    &Log::debug("Starting Misc::filename_splitter sub");
    &Log::debug1("Opts are: filename=>'$filename'");
    my ( $datas, $folder, $image ) =
      $filename =~ qr@^\s*\[([^\]]*)\]\s*(.*)/([^/]*)$@;
    if ( !defined($datas) ) {
        Vcenter::Path->throw(
            error => 'Could not split filename, not according to regex',
            path  => $filename
        );
    }
    &Log::debug( "Finished Misc::filename_splitter sub");
    &Log::debug( "Opts are: datastore=>'$datas', folder=>'$folder', image=>'$image'");
    return [ $datas, $folder, $image ];
}

=pod

=head2 generate_vmname

=head3 PURPOSE

Generates a virtual machine name according to standards

=head3 PARAMETERS

=over

=item ticket

The ticket the machine is going to be attached to

=item username

The username who is requesting the creation

=item os_temp

The os_template being used

=back

=head3 RETURNS

A standard virtual machine name

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

=head3 SEE ALSO

=cut

sub generate_vmname {
    my ( $ticket, $username, $os_temp ) = @_;
    &Log::debug( "Starting Misc::generate_vmname sub");
    &Log::debug( "Opts are: ticket=>'$ticket', username=>'$username', os_temp=>'$os_temp'");
    my $vmname = $ticket . "-" . $username . "-" . $os_temp . "-" . &Misc::random_3digit;
    &Log::debug("Vmname=>'$vmname'");
    &Log::debug("Finishing Misc::generate_vmname sub");
    return $vmname;
}

=pod

=head2 uniq_vmname

=head3 PURPOSE

Generates a uniq virtual machine name according to standards

=head3 PARAMETERS

=over

=item ticket

The ticket the machine is going to be attached to

=item username

The username who is requesting the creation

=item os_temp

The os_template being used

=back

=head3 RETURNS

An uniq virtual machine name

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

=head3 SEE ALSO

=cut

sub uniq_vmname {
    my ( $ticket, $username, $os_temp ) = @_;
    &Log::debug( "Starting Misc::uniq_vmname sub");
    &Log::debug1( "Opts are: ticket=>'$ticket', username=>'$username', os_temp=>'$os_temp'");
    my $vmname = &Misc::generate_vmname( $ticket, $username, $os_temp );
    while ( &VCenter::exists_entity( $vmname, 'VirtualMachine' ) ) {
        &Log::debug("Generated name not uniq, regenerating");
        $vmname = &Misc::generate_vmname( $ticket, $username, $os_temp );
    }
    &Log::debug("Return=>'$vmname'");
    &Log::debug("Finishing Misc::uniq_vmname sub");
    return $vmname;
}

=pod

=head2 ticket_list

=head3 PURPOSE

Generates a list with all provisioned tickets on VCenter

=head3 PARAMETERS

=over

=back

=head3 RETURNS

Hash ref containing ticket and first seen owner

=head3 DESCRIPTION

Machine names are used to idetify unseen tickets and added to hash

=head3 THROWS

=head3 COMMENTS

=head3 SEE ALSO

=cut

sub ticket_list {
    &Log::debug("Starting Misc::ticket_list sub");
    my $machines = Vim::find_entity_views(
        view_type  => 'VirtualMachine',
        properties => ['name']
    );
    my %tickets = ();
    for my $machine (@$machines) {
        &Log::debug1("Iterating through=>'" . $machine->name . "'");
        my $hash = &Misc::vmname_splitter( $machine->name );
        if ( $hash->{ticket} ne 'unknown'
            and !defined( $tickets{ $hash->{ticket} } ) )
        {
            $tickets{ $hash->{ticket} } = $hash->{username};
        } elsif ( defined( $tickets{ $hash->{ticket} } ) ) {
            if ( !($tickets{ $hash->{ticket} } =~ /$hash->{username}/) ) {
                &Log::debug("Adding new owner to hash");
                $tickets{ $hash->{ticket} } .= "," .$hash->{username};
            } else {
                &Log::debug("Owner is already added to hash");
            }
        }
    }
    &Log::debug("Finishing Misc::ticket_list sub");
    &Log::dumpobj( "tickets", %tickets );
    return \%tickets;
}

=pod

=head2 user_ticket_list

=head3 PURPOSE

Generates hash with users provisioned tickets

=head3 PARAMETERS

=over

=item name

Username to get tickets of

=back

=head3 RETURNS

Hash ref containing tickets

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

=head3 SEE ALSO

=cut

sub user_ticket_list {
    my ($name) = @_;
    &Log::debug("Starting Misc::user_ticket_list sub");
    &Log::debug1("Opts are: name=>'$name'");
    my $machines = Vim::find_entity_views(
        view_type  => 'VirtualMachine',
        properties => ['name'],
        filter     => { name => qr/^[^-]*-$name-/ }
    );
    &Log::dumpobj( "machines", $machines );
    my %tickets = ();
    for my $machine (@$machines) {
        &Log::debug1("Iterating through=>'" . $machine->name . "'");
        my $hash = &Misc::vmname_splitter( $machine->name );
        if ( $hash->{username} eq $name
            and !defined( $tickets{ $hash->{ticket} } ) )
        {
            $tickets{ $hash->{ticket} } = 1;
        }
    }
    &Log::debug("Finishing Misc::user_ticket_list sub");
    &Log::dumpobj( "tickets", %tickets );
    return \%tickets;
}

1
