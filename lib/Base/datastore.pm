package datastore;

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

=head1 DATASTORE_MAIN

=head2 DESCRIPTION

    This is the main entry sub to the datastore functions. All further functions can be reached from here

=cut

our $module_opts = {
    helper    => 'DATASTORE',
    functions => {
        add => {
            function => \&datastore_add,
            opts => {
                datastore => {
                    type => "=s",
                    help => "Name of datastore",
                    required => 1,
                },
            },
        },
        delete => {
            function => \&datastore_delete,
            opts => {
                datastore => {
                    type => "=s",
                    help => "Name of datastore",
                    required => 1,
                },
            },
        },
        list => {
            function => \&datastore_list,
            opts => {
            },
        },
        info => {
            function => \&datastore_info,
            opts => {
                datastore => {
                    type => "=s",
                    help => "Name of datastore",
                    required => 0,
                    default => 0,
                },
            },
        },
    },
};

sub main {
    &Log::debug("Datastore::main sub started");
    &misc::option_parser( $module_opts, "main" );
}

sub datastore_add {

}

sub datastore_delete {

}

sub datastore_list {

}
1;
__END__
