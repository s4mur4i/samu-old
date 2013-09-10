package admin;

use strict;
use warnings;
use Base::misc;
use BB::Common;

my $help = 0;

BEGIN {
    use Exporter();
    our ( @ISA, @EXPORT );

    @ISA    = qw(Exporter);
    @EXPORT = qw(&main);
}

### subs

=pod

=head1 ADMIN_MAIN

=head2 DESCRIPTION

    This is the main entry sub to the admin functions. All further functions can be reached from here

=cut

our $module_opts = {
    helper    => 'ADMIN',
    functions => {
        cleanup => {
            function => \&cleanup,
            opts     => {},
        },
        templates => {
            function => \&templates,
            opts     => {},
        },
        test => {
            function => \&test,
            opts     => {},
        },
    },
};

sub main {
    &Log::debug("Admin::main sub started");
    &misc::option_parser( $module_opts, "main" );
}

sub cleanup {
    &Log::debug("Starting Admin::cleanup sub");
    my @types = ( 'ResourcePool', 'Folder', 'DistributedVirtualSwitch' );
    for my $type (@types) {
        &Log::normal("Looping through $type");
        my $entities =
          Vim::find_entity_views( view_type => $type, properties => ['name'] );
        foreach my $entity (@$entities) {
            &Log::debug("Checking $entity in $type");
            if ( &VCenter::check_if_empty_entity( $entity->name, $type ) ) {
                &Log::normal( "Deleting entity=>'"
                      . $entity->name
                      . "',type=>'"
                      . $type
                      . "'" );
                &VCenter::destroy_entity( $entity->name, $type );
            }
        }
    }
}

sub templates {
    &Log::debug("Admin::templates sub started");
    my $keys = &Support::get_keys('template');
    my $max  = &Misc::array_longest($keys);
    for my $template (@$keys) {
        &Log::debug("Element working on:'$template'");
        my $path = &Support::get_key_value( 'template', $template, 'path' );
        my $length = ( $max - length($template) ) + 1;
        &Log::normal( "Name:'$template'" . " " x $length . "Path:'$path'" );
    }
}

sub test {
    &Log::debug("Admin::test started");
    my $si_moref = ManagedObjectReference->new(
        type  => 'ServiceInstance',
        value => 'ServiceInstance'
    );
    my $si_view = Vim::get_view( mo_ref => $si_moref );
    &Log::normal( "Server Time : " . $si_view->CurrentTime() );
}

1
__END__
