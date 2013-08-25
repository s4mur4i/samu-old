package admin;

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

=head1 ADMIN_MAIN

=head2 DESCRIPTION

    This is the main entry sub to the admin functions. All further functions can be reached from here

=cut

our $module_opts = {
    helper => 'ADMIN',
    functions => {
        cleanup => {
            helper => 'ADMIN_CLEANUP_function',
            function => \&cleanup,
            },
        },
};

sub main {
    &Log::debug("Admin::main sub started");
    &misc::option_parser($module_opts,"main");
}

1;
__END__
