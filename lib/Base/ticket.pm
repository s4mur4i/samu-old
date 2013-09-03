package ticket;

use strict;
use warnings;
use Base::misc;

my $help = 0;

BEGIN() {
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
            helper   => 'TICKET_info_function',
            function => \&ticket_info,
        },
        list => {
            helper   => 'TICKET_list_function',
            function => \&ticket_list
        },
    },
};

sub main {
    &Log::debug("Ticket::main sub started");
    &misc::option_parser( $module_opts, "main" );
}

sub ticket_info {

}

sub ticket_list {

}
1;
__END__
