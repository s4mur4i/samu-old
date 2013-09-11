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
        &Log::debug( "Getting information about '" . $vm->name . "'" );
        &Guest::short_vm_info( $vm->name );
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

}
1;
__END__
