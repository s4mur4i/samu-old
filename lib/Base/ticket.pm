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
            helper   => 'TICKET_list_function',
            function => \&ticket_list,
        },
        on => {
            function => \&ticket_on,
        },
        off => {
            function => \&ticket_off,
        },
    },
};

sub main {
    &Log::debug("Ticket::main sub started");
    &misc::option_parser( $module_opts, "main" );
}

sub ticket_info {
    &Log::debug("Startin Ticket::ticket_info sub");
    my $ticket = Opts::get_option('ticket');
    &Log::debug("Information about ticket=>'$ticket'");
    my $machines = Vim::find_entity_views(
        view_type  => 'VirtualMachine',
        properties => ['name'],
        filter     => { name => qr/^$ticket-/ }
    );
    for my $vm (@$machines) {
        &Log::debug("Getting information about ''$vm->name'");
        &Guest::short_vm_info( $vm->name );
    }
}

sub ticket_list {

}
1;
__END__
