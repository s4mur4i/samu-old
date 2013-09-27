package network;

use strict;
use warnings;
use Base::misc;

BEGIN() {
    use Exporter();
    our ( @ISA, @EXPORT );

    @ISA    = qw(Exporter);
    @EXPORT = qw(&main);
}

### subs

our $module_opts = {
    helper    => 'NETWORK',
    functions => {
        add => {
            function => \&network_add,
            opts     => {
                ticket => {
                    type     => "=s",
                    help     => "Ticket to add network to",
                    required => 1,
                },
                type => {
                    type     => "=s",
                    help     => "Type of network to add",
                    required => 1,
                },
            },
        },
        list_switch => {
            function => \&list_switch,
            opts     => {},
        },
        list_dvp => {
            function => \&list_dvp,
            opts     => {},
        },
        delete => {
            function => \&network_delete,
            opts     => {
                name => {
                    type     => "=s",
                    help     => "Name of switch to delete",
                    required => 1,
                },
            },
        },
    },
};

sub main {
    &Log::debug("network::main sub started");
    &misc::option_parser( $module_opts, "main" );
}

sub network_add {
    &Log::debug("Starting network::network_add sub");
    my $ticket = Opts::get_option('ticket');
    my $type   = Opts::get_option('type');
    &Log::debug("Requested options, ticket=>'$ticket', type=>'$type'");
    my $name = $ticket . "-" . $type . "-" . &Misc::random_3digit;
    while ( &VCenter::exists_entity( $name, 'DistributedVirtualPortgroup' ) ) {
        $name = $ticket . "-" . $type . "-" . &Misc::random_3digit;
    }
    if ( !&VCenter::exists_entity( $ticket, 'DistributedVirtualSwitch' ) ) {
        &Log::debug("Switch does not exist, need to create");
        &VCenter::create_switch($ticket);
    }
    else {
        &Log::debug("Switch already exists");
    }
    &VCenter::create_dvportgroup( $name, $ticket );
    &Log::debug("Finished creating port group");
    return 1;
}

sub list_switch {
    &Log::debug("Starting network::list_switch sub");
    my $views = Vim::find_entity_views( view_type => 'Network', properties => [ 'name' ] );
    if ( !defined( $viewss ) ) {
        Entity::NumException->throw( error => 'No switch found', entity => 'Network', count => '0' );
    }
    foreach( @$views ) {
        &Log::dumpobj( "switch", $_ );
        print "name:" . $_->name . "\n";
    }
}

sub list_dvp {
    &Log::debug("Starting network::list_dvp sub");
    my $networks = Vim::find_entity_views( view_type => 'DistributedVirtualPortgroup', properties => [ 'name' ] );
    if ( !defined( $networks ) ) {
        Entity::NumException->throw( error => 'No DVP found', entity => 'DistributedVirtualPortGroup', count => '0' );
    }
    foreach( @$networks ) {
        &Log::dumpobj( "dvp", $_ );
        print "name:" . $_->name . "\n";
    }

}

sub network_delete {
    &Log::debug("Starting network::network_delete sub");
}

1;
__END__
