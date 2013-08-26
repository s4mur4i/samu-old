package admin;

use strict;
use warnings;
use BB::Log;
use Base::misc;
use BB::Misc;
use BB::Support;

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
            helper => 'ADMIN_function/ADMIN_cleanup_function',
            function => \&cleanup,
            },
        templates => {
            helper=> 'ADMIN_function/ADMIN_templates_function',
            function => \&templates,
        },
        },
};

sub main {
    &Log::debug("Admin::main sub started");
    &misc::option_parser($module_opts,"main");
}

sub cleanup {

}

sub templates {
    &Log::debug("Admin::templates sub started");
    my $keys = &Support::get_keys('template');
    my $max = &Misc::array_longest($keys);
    for my $template ( @$keys ) {
        &Log::debug("Element working on:'$template'");
        my $path = &Support::get_key_value('template',$template,'path');
        my $length = ( $max - length( $template ) ) +1;
        &Log::normal("Name:'$template'" . " " x $length . "Path:'$path'");
    }
}

1
__END__
