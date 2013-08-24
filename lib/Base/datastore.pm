package datastore;

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

=head1 DATASTORE_MAIN

=head2 DESCRIPTION

    This is the main entry sub to the datastore functions. All further functions can be reached from here

=cut

our $module_opts = {
    helper => 'DATASTORE',
    functions => {
        add => {
            helper => 'DATASTORE_add_function',
            function => \&datastore_add, },
        delete => {
            helper => 'DATASTORE_delete_function',
            function => \&datastore_delete,
            },
        list => {
            helper => 'DATASTORE_list_function',
            function => \&datastore_list
            },
        },
};

sub main {
    &Log::debug("Datastore::main sub started");
    &misc::option_parser($module_opts,"main");
}

sub datastore_add {

}

sub datastore_delete {

}

sub datastore_list {

}
1;
__END__
