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
    },
};

sub main {
    &Log::debug("Ticket::main sub started");
    &misc::option_parser( $module_opts, "main" );
}

sub ticket_info {
    &Log::debug("Starting Ticket::ticket_info sub");
    my $ticket = Opts::get_option('ticket');
    &Log::debug("Information about ticket=>'$ticket'");
    my $machines = &VCenter::ticket_vms_name($ticket);
    for my $vm (@$machines) {
        &Log::debug( "Getting information about '" . $vm . "'" );
        &Guest::short_vm_info( $vm );
    }
    return 1;
}

sub ticket_on {
    &Log::debug("Starting Ticket::on sub");
    my $ticket = Opts::get_option('ticket');
    &Log::debug("Powering on ticket, ticket=>'$ticket'");
    my $machines = &VCenter::ticket_vms_name($ticket);
    for my $vm (@$machines) {
        &Log::normal( "Powering on '" . $vm->name . "'" );
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
        &Log::normal( "Powering off '" . $vm->name . "'" );
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
            &Log::normal($string);
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
