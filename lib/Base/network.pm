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
        create => {
            function => \&create_net,
            opts     => {
                type => {
                    type     => "=s",
                    help     => "Type of interface to create",
                    required => 1,
                },
                ticket => {
                    type     => "=s",
                    help     => "Ticket to add network to",
                    required => 1,
                },
                vms => {
                    type => "=s",
                    help =>
"A comma seperated list of vms to add to interface, Ex: test1,test2,test3",
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
                    help     => "Name of device to delete",
                    required => 1,
                },
                switch => {
                    type => "",
                    help => "Delete switch",
                    required => 0,
                    default => 0,
                },
                dvp => {
                    type => "",
                    help => "Delete Distributed virtual Portgroup",
                    required => 0,
                    default => 0,
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
    my $views =
      Vim::find_entity_views( view_type => 'DistributedVirtualSwitch', properties => ['name'] );
    if ( !defined($views) ) {
        Entity::NumException->throw(
            error  => 'No switch found',
            entity => 'DistributedVirtualSwitch',
            count  => '0'
        );
    }
    foreach (@$views) {
        &Log::dumpobj( "switch", $_ );
        print "switch_name:" . $_->name . "\n";
    }
    return 1;
}

sub list_dvp {
    &Log::debug("Starting network::list_dvp sub");
    my $networks = Vim::find_entity_views(
        view_type  => 'DistributedVirtualPortgroup',
        properties => ['name']
    );
    if ( !defined($networks) ) {
        Entity::NumException->throw(
            error  => 'No DVP found',
            entity => 'DistributedVirtualPortGroup',
            count  => '0'
        );
    }
    foreach (@$networks) {
        &Log::dumpobj( "dvp", $_ );
        print "dvp_name:" . $_->name . "\n";
    }
    return 1;
}

sub network_delete {
    &Log::debug("Starting network::network_delete sub");
    my $name = &Opts::get_option('name');
    if ( &Opts::get_option('switch')) {
        &Log::debug("Going to delete switch");
        &VCenter::destroy_entity( $name, 'DistributedVirtualSwitch' );
    } elsif (&Opts::get_option('dvp')) {
        &Log::debug("Going to delete distributed virtual portgroup");
        my $moref = &Guest::entity_property_view( $name, 'DistributedVirtualPortgroup', 'config.distributedVirtualSwitch');
        my $switch_view = &VCenter::moref2view( $moref->get_property('config.distributedVirtualSwitch') );
        &VCenter::destroy_entity( $name, 'DistributedVirtualPortgroup');
        if ( &VCenter::check_if_empty_entity( $switch_view->name, 'DistributedVirtualSwitch') ) {
            &VCenter::destroy_entity( $switch_view->name, 'DistributedVirtualSwitch' );
        } else {
            &Log::debug("Switch not empty");
        }
    } else {
        &Log::warning("No option specified, Please give either one");
    }
    return 1;
}

sub create_net {

}

1;
__END__
