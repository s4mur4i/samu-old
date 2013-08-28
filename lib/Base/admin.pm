package admin;

use strict;
use warnings;
use BB::Log;
use Base::misc;
use BB::Misc;
use BB::Support;
use BB::VCenter;

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
            helper => 'ADMIN_functions/ADMIN_cleanup_function',
            function => \&cleanup,
            },
        templates => {
            helper => 'ADMIN_functions/ADMIN_templates_function',
            function => \&templates,
        },
        test => {
            helper => 'ADMIN_functions/ADMIN_test_function',
            function => \&test,
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
    my %opt = ();
    &VCenter::SDK_options(%opt);
    &VCenter::connect_vcenter();
    my $si_moref = ManagedObjectReference->new(type => 'ServiceInstance',value => 'ServiceInstance');
    my $si_view = Vim::get_view(mo_ref => $si_moref);
    &Log::normal("Server Time : ". $si_view->CurrentTime());
    &VCenter::disconnect_vcenter();
}
1
__END__
