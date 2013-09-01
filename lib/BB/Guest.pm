package Guest;

use strict;
use warnings;

BEGIN {
    use Exporter;
    our @ISA = qw( Exporter );
    our @EXPORT = qw( &entity_name_view &vm_memory &vm_numcpu &find_last_snapshot );
}

sub entity_name_view($$) {
    my ( $name, $type ) = @_;
    &Log::debug("Retrieving entity name view, name=>'$name', type=>'$type'");
    my $view = Vim::find_entity_view( view_type => $type, properties => [ 'name' ], filter => { name => $name } );
    return $view;
}

sub vm_memory($$) {
    my ( $name ) = @_;
    &Log::debug("Retrieving VirtualMachine memory size in MB, name=>'$name'");
    my $view = Vim::find_entity_view( view_type => 'VirtualMachine', properties => [ 'summary.config.memorySizeMB' ], filter => { name => $name } );
    return $view->get_property( 'summary.config.memorySizeMB' );
}

sub vm_numcpu($) {
    my ( $name ) = @_;
    &Log::debug("Retrieving VirtualMachine Cpu count, name=>'$name'");
    my $view = Vim::find_entity_view( view_type => 'VirtualMachine', properties => [ 'summary.config.numCpu' ], filter => { name => $name } );
    return $view->get_property( 'summary.config.numCpu' );
}

sub find_last_snapshot {
    my ( $snapshot_view ) = @_;
    &Log::debug("Starting Guest::find_last_snapshot sub, name=>'" . $snapshot_view->name . "',id=>'" . $snapshot_view->id . "'");
    if ( defined( $snapshot_view->[0]->{'childSnapshotList'} ) ) {
        &find_last_snapshot( $snapshot_view->[0]->{'childSnapshotList'} );
    } else {
        &Log::debug("Found snapshot returning, name=>'" . $snapshot_view->name . "'");
        return $snapshot_view;
    }
}

sub generate_network_setup {
    my ( $os_temp ) = @_;
    my @return;
    &Log::debug("Starting Guest::generate_network_sub, os_temp=>'$os_temp'");
    if ( defined( &Support::get_key_info( 'template', $os_temp ) ) ) {
        my $os_temp_path = &Support::get_key_value( 'template', $os_temp, 'path' );
        my $os_temp_view = &VCenter::moref2view( &VCenter::path2moref( $os_temp_path ) );
        my @keys;
        foreach ( @{$os_temp_view->config->hardware->device} ) {
            my $interface = $_;
            if ( !$interface->isa( 'VirtualEthernetCard' ) ) {
                &Log::debug("Device is not a network interface, skipping");
                next;
            }
            &Log::debug("Pushing " . $interface->key . " to \@keys");
            push( @keys, $interface->key )
        }
        my @mac;
        &Log::debug("Need to generate array of incremented macs");
        while ( @mac != @keys ) {
            if ( @mac == 0 ) {
                &Log::debug("First mac needs to be generated");
                push( @mac, &Misc::generate_uniq_mac );
            } else {
                &Log::debug("Need to increment last mac");
                my $last =$mac[ -1 ];
                my $new_mac;
                eval { $new_mac = &Misc::increment_mac( $last ); };
                if ( $@ ) {
                    &Log::debug("Increment is not possible, need to regenerate all macs");
                    @mac = ();
                } else {
                    &Log::debug("Need to investigate if mac is already used");
                    if ( !&Misc::mac_compare( $new_mac ) ) {
                        &Log::debug("Pushing to array the mac=>'$new_mac'");
                        push( @mac, $new_mac );
                    }
                }
            }
        }
        for ( my $i =0;$i<@keys;$i++ ) {
            my $ethernetcard =VirtualE1000->new( addressType => 'Manual', macAddress => $mac[ $i ], wakeOnLanEnabled => 1, key => $keys[ $i ] );
            my $operation = VirtualDeviceConfigSpecOperation->new( 'edit' );
            my $deviceconfigspec = VirtualDeviceConfigSpec->new( device => $ethernetcard, operation => $operation );
            push( @return, $deviceconfigspec );
        }
    } else {
        Template::Status->throw( error => 'Template does not exists', template => $os_temp );
    }
    return \@return;
}


1
__END__
