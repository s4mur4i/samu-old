package network;

use strict;
use warnings;
use Base::misc;

=pod

=head1 network.pm

Subroutines from Base/network.pm

=cut

BEGIN() {
    use Exporter();
    our ( @ISA, @EXPORT );

    @ISA    = qw(Exporter);
    @EXPORT = qw();
}

our $module_opts = {
    helper    => 'NETWORK',
    functions => {
        add => {
            function        => \&network_add,
            vcenter_connect => 1,
            opts            => {
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
            function        => \&create_net,
            vcenter_connect => 1,
            opts            => {
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
            function        => \&list_switch,
            vcenter_connect => 1,
            opts            => {},
        },
        list_dvp => {
            function        => \&list_dvp,
            vcenter_connect => 1,
            opts            => {},
        },
        delete => {
            function        => \&network_delete,
            vcenter_connect => 1,
            opts            => {
                name => {
                    type     => "=s",
                    help     => "Name of device to delete",
                    required => 1,
                },
                switch => {
                    type     => "",
                    help     => "Delete switch",
                    required => 0,
                    default  => 0,
                },
                dvp => {
                    type     => "",
                    help     => "Delete Distributed virtual Portgroup",
                    required => 0,
                    default  => 0,
                },
            },
        },
    },
};

=pod

=head2 main

=head3 PURPOSE



=head3 PARAMETERS

=over

=back

=head3 RETURNS

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

=head3 TEST COVERAGE

=cut

sub main {
    &Log::debug("Starting Network::main sub");
    &misc::option_parser( $module_opts, "main" );
    &Log::debug("Finishing Network::main sub");
    return 1;
}

=pod

=head2 network_add

=head3 PURPOSE



=head3 PARAMETERS

=over

=back

=head3 RETURNS

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

=head3 TEST COVERAGE

=cut

sub network_add {
    &Log::debug("Starting Network::network_add sub");
    my $ticket = Opts::get_option('ticket');
    my $type   = Opts::get_option('type');
    &Log::debug1("Opts are: ticket=>'$ticket', type=>'$type'");
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
    &Log::debug("Finishing Network::network_add sub");
    return 1;
}

=pod

=head2 list_switch

=head3 PURPOSE



=head3 PARAMETERS

=over

=back

=head3 RETURNS

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

=head3 TEST COVERAGE

=cut

sub list_switch {
    &Log::debug("Starting Network::list_switch sub");
    my $views = Vim::find_entity_views(
        view_type  => 'DistributedVirtualSwitch',
        properties => ['name']
    );
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
    &Log::debug("Finishing Network::list_switch sub");
    return 1;
}

=pod

=head2 list_dvp

=head3 PURPOSE



=head3 PARAMETERS

=over

=back

=head3 RETURNS

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

=head3 TEST COVERAGE

=cut

sub list_dvp {
    &Log::debug("Starting Network::list_dvp sub");
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
    &Log::debug("Finishing Network::list_dvp sub");
    return 1;
}

=pod

=head2 network_delete

=head3 PURPOSE



=head3 PARAMETERS

=over

=back

=head3 RETURNS

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

=head3 TEST COVERAGE

=cut

sub network_delete {
    &Log::debug("Starting Network::network_delete sub");
    my $name = &Opts::get_option('name');
    &Log::debug1("Opts are: name=>'$name'");
    if ( &Opts::get_option('switch') ) {
        &Log::debug("Going to delete switch");
        &VCenter::destroy_entity( $name, 'DistributedVirtualSwitch' );
    }
    elsif ( &Opts::get_option('dvp') ) {
        &Log::debug("Going to delete distributed virtual portgroup");
        my $moref =
          &Guest::entity_property_view( $name, 'DistributedVirtualPortgroup',
            'config.distributedVirtualSwitch' );
        my $switch_view =
          &VCenter::moref2view(
            $moref->get_property('config.distributedVirtualSwitch') );
        &VCenter::destroy_entity( $name, 'DistributedVirtualPortgroup' );
        if (
            &VCenter::check_if_empty_entity(
                $switch_view->name, 'DistributedVirtualSwitch'
            )
          )
        {
            &VCenter::destroy_entity( $switch_view->name,
                'DistributedVirtualSwitch' );
        }
        else {
            &Log::debug("Switch not empty");
        }
    }
    else {
        &Log::warning("No option specified, Please give either one");
    }
    &Log::debug("Finishing Network::network_delete sub");
    return 1;
}

=pod

=head2 create_net

=head3 PURPOSE



=head3 PARAMETERS

=over

=back

=head3 RETURNS

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

=head3 TEST COVERAGE

=cut

sub create_net {
    &Log::debug("Starting Network::create_net sub");
    print "Not implemented yet\n";
    &Log::debug("Finishing Network::create_net sub");
    return 1;
}

1
