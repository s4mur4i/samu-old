package ticket;

use strict;
use warnings;
use Base::misc;

my $help = 0;

BEGIN {
    use Exporter();
    our ( @ISA, @EXPORT );

    @ISA    = qw(Exporter);
    @EXPORT = qw(&main);
}

### subs

=pod

=head1 TICKET_MAIN

=head2 DESCRIPTION

    This is the main entry sub to the datastore functions. All further functions can be reached from here

=cut

our $module_opts = {
    helper    => 'TICKET',
    functions => {
        info => {
            function => \&ticket_info,
            opts     => {
                ticket => {
                    type     => "=s",
                    help     => "Ticket to list information about",
                    required => 1,
                },
            },
        },
        list => {
            function => \&ticket_list,
            opts     => {},
        },
        on => {
            function => \&ticket_on,
            opts     => {
                ticket => {
                    type     => "=s",
                    help     => "Ticket to power on",
                    required => 1,
                },
            },
        },
        off => {
            function => \&ticket_off,
            opts     => {
                ticket => {
                    type     => "=s",
                    help     => "Ticket to power off",
                    required => 1,
                },
            },
        },
        delete => {
            function => \&ticket_delete,
            opts     => {
                ticket => {
                    type     => "=s",
                    help     => "Ticket to delete",
                    required => 1,
                },
            },
        },
    },
};

sub main {
    &Log::debug("Ticket::main sub started");
    &misc::option_parser( $module_opts, "main" );
}

sub ticket_delete {
    &Log::debug("Starting Ticket::ticket_delete sub");
    my $ticket = Opts::get_option('ticket');
    &Log::debug("Delete ticket=>'$ticket'");
    my $machines = &VCenter::ticket_vms_name($ticket);
    for my $vm (@$machines) {
        &Log::debug("Powering off VM if not already powered off");
        &Guest::poweroff($vm);
        &Log::debug( "Deleting vm '" . $vm . "'" );
        &VCenter::destroy_entity( $vm, 'VirtualMachine' );
    }
    for my $type (qw(ResourcePool Folder)) {
        &Log::debug( "Deleting type '" . $type . "'" );
        my $entities = Vim::find_entity_views(
            view_type  => $type,
            properties => ['name'],
            filter     => { name => $ticket }
        );
        for my $entity (@$entities) {
            &Log::debug(
                "Deleting entity " . $entity->name . " in type " . $type );
            &VCenter::destroy_entity( $entity->name, $type );
        }
    }
    my $switch_view = Vim::find_entity_view(
        view_type  => 'DistributedVirtualSwitch',
        properties => ['name'],
        filter     => { name => $ticket }
    );
    if ( defined($switch_view) ) {
        &Log::debug("Found switch for ticket, deleting");
        &VCenter::destroy_entity( $switch_view->name,
            'DistributedVirtualSwitch' );
    }
    else {
        &Log::debug("No switch present for ticket");
    }
    print "Ticket deleted succesfully\n";
    return 1;
}

sub ticket_info {
    &Log::debug("Starting Ticket::ticket_info sub");
    my $ticket = Opts::get_option('ticket');
    &Log::debug("Information about ticket=>'$ticket'");
    my $machines = &VCenter::ticket_vms_name($ticket);
    for my $vm (@$machines) {
        &Log::debug( "Getting information about '" . $vm . "'" );
        &Log::debug("Starting Guest::short_vm_info sub, name=>'$vm'");
        &VCenter::num_check( $vm, 'VirtualMachine' );
        my $view = Vim::find_entity_view(
            view_type  => 'VirtualMachine',
            properties => [ 'name', 'guest', 'summary.runtime.powerState' ],
            filter => { name => $vm }
        );
        print "VMname:'" . $view->name . "\n";
        my $powerState = $view->get_property('summary.runtime.powerState');
        print "\tPower State:'" . $powerState->val . "'\n";

        print "\tAlternate name: '"
          . &Guest::get_altername( $view->name ) . "'\n";
        if ( $view->guest->toolsStatus eq 'toolsNotInstalled' ) {
            print "\tTools not installed. Cannot extract some information\n";
        }
        else {
            if ( defined( $view->guest->net ) ) {
                foreach ( @{ $view->guest->net } ) {
                    my $string = "";
                    if ( defined( $_->ipAddress ) ) {
                        $string = "ipAddresses => [ "
                          . join( ", ", @{ $_->ipAddress } ) . " ]";
                    }
                    if ( defined( $_->network ) ) {
                        $string .= ", Network => '" . $_->network . "'";
                    }
                    if ( $string =~ /^$/ ) {
                        $string = "No network information could be extracted";
                    }
                    print "\t" . $string . "\n";
                }
                if ( defined( $view->guest->hostName ) ) {
                    print "\tHostname: '" . $view->guest->hostName . "'\n";
                }
            }
            else {
                print "\tNo network information available\n";
            }
        }
        my $vm_info = &Misc::vmname_splitter( $view->name );
        my $os;
        if ( $vm_info->{type} =~ /xcb/ ) {
            &Log::debug("Product is an XCB product");
            $os = "$vm_info->{family}_$vm_info->{version}";
        }
        elsif ( $vm_info->{type} ne 'unknown' ) {
            &Log::debug("Product is known");
            $os =
"$vm_info->{family}_$vm_info->{version}_$vm_info->{lang}_$vm_info->{arch}_$vm_info->{type}";
        }
        if ( $vm_info->{uniq} ne 'unknown' ) {
            if ( defined( &Support::get_key_info( 'template', $os ) ) ) {
                print "\tDefault login : '"
                  . &Support::get_key_value( 'template', $os, 'username' )
                  . "' / '"
                  . &Support::get_key_value( 'template', $os, 'password' )
                  . "'\n";
            }
            else {
                print
"\tRegex matched an OS, but no template found to it os => '$os'\n";
            }
        }
        else {
            print "\tVmname not standard name => '$vm'\n";
        }
    }
    return 1;
}

sub ticket_on {
    &Log::debug("Starting Ticket::on sub");
    my $ticket = Opts::get_option('ticket');
    &Log::debug("Powering on ticket, ticket=>'$ticket'");
    my $machines = &VCenter::ticket_vms_name($ticket);
    for my $vm (@$machines) {
        print "Powering on '" . $vm->name . "'\n";
        &Guest::poweron( $vm->name );
    }
    return 1;
}

sub ticket_off {
    &Log::debug("Starting Ticket::off sub");
    my $ticket = Opts::get_option('ticket');
    &Log::debug("Powering off ticket, ticket=>'$ticket'");
    my $machines = &VCenter::ticket_vms_name($ticket);
    for my $vm (@$machines) {
        print "Powering off '" . $vm->name . "'\n";
        &Guest::poweroff( $vm->name );
    }
    return 1;
}

sub ticket_list {
    &Log::debug("Starting Ticket::ticket_list sub");
    my $tickets = &Misc::ticket_list;
    &Log::debug("Finished collecting ticket list");
    my $dbh = &Kayako::connect_kayako();
    for my $ticket ( sort ( keys %{$tickets} ) ) {
        &Log::debug("Collecting information about ticket=>'$ticket'");
        if ( $ticket ne "" and $ticket ne "unknown" ) {
            my $string = "";
            $string = "Ticket: $ticket, owner: $$tickets{$ticket}";
            my $result = &Kayako::run_query( $dbh,
"select ticketstatustitle from swtickets where ticketid = '$ticket'"
            );
            if ( defined($result) ) {
                $string .=
                  ", ticket status: " . $$result{ticketstatustitle} . "";
                $result = &Kayako::run_query( $dbh,
"select fieldvalue from swcustomfieldvalues where typeid = '$ticket' and customfieldid = '25'"
                );
                if ( defined($result) or $$result{fieldvalue} ne "" ) {
                    my @result = split( " ", $$result{fieldvalue} );
                    foreach (@result) {
                        if ( $_ ne "" ) {
                            my $id;
                            if ( $_ =~ /^\s*\d+\s*$/ ) {
                                $id = $_;
                            }
                            elsif ( $_ =~ /\?id=\d+/ ) {
                                ($id) = $_ =~ /id=(\d+)\D?/;
                            }
                            else {
                                $id = $_;
                            }
                            $string .= ", bugzilla: " . $id;
                            my $content = &Bugzilla::bugzilla_status($id);
                            if ( defined($content) ) {
                                $string .= ", bugzilla status: $content";
                            }

                        }
                    }
                }
            }
            print $string . "\n";
        }
        else {
            &Log::debug("Ticket name is empty or unknown");
        }
    }
    &Log::debug("Finished printing ticket information");
    &Kayako::disconnect_kayako($dbh);
}
1;
__END__
