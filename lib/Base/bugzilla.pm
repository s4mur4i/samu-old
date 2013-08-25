package bugzilla;

use strict;
use warnings;
use BB::Log;
use Base::misc;

my $help = 0;
BEGIN() {
    use Exporter();
    our (@ISA, @EXPORT);

    @ISA         = qw(Exporter);
    @EXPORT      = qw(&main);
}

### subs

=pod

=head1 BUGZILLA_MAIN

=head2 DESCRIPTION

    This is the main entry sub to the bugzillz functions. All further functions can be reached from here

=cut

our $module_opts = {
    helper => 'BUGZILLA',
    functions => {
        info => {
            helper => 'BUGZILLA_info_function',
            function => \&info,
            },
        },
};

sub main {
    &Log::debug("Bugzilla::main sub started");
    &misc::option_parser($module_opts,"main");
}

1;
__END__
