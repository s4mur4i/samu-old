package kayako;

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

=head1 KAYAKO_MAIN

=head2 DESCRIPTION

    This is the main entry sub to the kayako functions. All further functions can be reached from here

=cut

our $module_opts = {
    helper    => 'KAYAKO',
    functions => {
        info => {
            function => \&info,
            opts => {
                ticket => {
                    type => '=s',
                    help => "Number of ticket to gather info",
                    required => 1,
                },
            },
        },
    },
};

sub main {
    &Log::debug("Kayako::main sub started");
    &misc::option_parser( $module_opts, "main" );
}

1;
__END__
