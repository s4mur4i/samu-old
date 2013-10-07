package kayako;

use strict;
use warnings;
use Base::misc;

my $help = 0;

BEGIN {
    use Exporter();
    our ( @ISA, @EXPORT );

    @ISA    = qw(Exporter);
    @EXPORT = qw();
}

our $module_opts = {
    helper    => 'KAYAKO',
    functions => {
        info => {
            function => \&info,
            opts     => {
                ticket => {
                    type     => '=s',
                    help     => "Number of ticket to gather info",
                    required => 1,
                },
            },
        },
    },
};

=pod

=head1 main

=head2 PURPOSE



=head2 PARAMETERS

=back

=over

=head2 RETURNS

=head2 DESCRIPTION

=head2 THROWS

=head2 COMMENTS

=head2 SEE ALSO

=cut

sub main {
    &Log::debug("Starting Kayako::main sub");
    &misc::option_parser( $module_opts, "main" );
    &Log::debug("Finishing Kayako::main sub");
    return 1;
}

1;
__END__
