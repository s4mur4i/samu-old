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
            opts => {
                ticket => {
                    entity => "=s",
                    help => "Ticket to add network to",
                    required => 1,
                },
                type => {
                    entity => "=s",
                    help => "Type of network to add",
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
}

1;
__END__
