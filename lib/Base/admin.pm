package admin;

use strict;
use warnings;
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
            function => \&cleanup,
            opts => {},
            },
        templates => {
            function => \&templates,
            opts => {},
        },
        test => {
            function => \&test,
            opts => {},
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

sub test {
    my $si_moref = ManagedObjectReference->new(type => 'ServiceInstance',value => 'ServiceInstance');
    my $si_view = Vim::get_view(mo_ref => $si_moref);
    &Log::normal("Server Time : ". $si_view->CurrentTime());
}

1
__END__
