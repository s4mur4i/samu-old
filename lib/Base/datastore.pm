package datastore;

use strict;
use warnings;
use Base::misc;

my $help = 0;

=pod

=head1 datastore.pm

Subroutines from Base/datastore.pm

=cut

BEGIN() {
    use Exporter();
    our ( @ISA, @EXPORT );

    @ISA    = qw(Exporter);
    @EXPORT = qw();
}

our $module_opts = {
    helper    => 'DATASTORE',
    functions => {
        add => {
            function        => \&datastore_add,
            vcenter_connect => 1,
            opts            => {
                datastore => {
                    type     => "=s",
                    help     => "Name of datastore",
                    required => 1,
                    default => "",
                },
            },
        },
        delete => {
            function        => \&datastore_delete,
            vcenter_connect => 1,
            opts            => {
                datastore => {
                    type     => "=s",
                    help     => "Name of datastore",
                    required => 1,
                    default => "",
                },
            },
        },
        list => {
            function        => \&datastore_list,
            vcenter_connect => 1,
            opts            => {},
        },
        info => {
            function        => \&datastore_info,
            vcenter_connect => 1,
            opts            => {
                datastore => {
                    type     => "=s",
                    help     => "Name of datastore",
                    required => 0,
                    default  => 0,
                },
            },
        },
    },
};

=pod

=head1 module_opts

=head2 PURPOSE

Return Module_opts hash for testing

=head2 PARAMETERS

=over

=back

=head2 RETURNS

Hash ref containing module_opts

=head2 DESCRIPTION

=head2 THROWS

=head2 COMMENTS

=head2 TEST COVERAGE

=cut

sub module_opts {
        return $module_opts;
}

=pod

=head2 main

=head3 PURPOSE



=head3 PARAMETERS

=over

=back

=head3 RETURNS

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

=head3 TEST COVERAGE

=cut

sub main {
    &Log::debug("Starting Datastore::main sub");
    &misc::option_parser( $module_opts, "main" );
    &Log::debug("Finishing Datastore::main sub");
    return 1;
}

=pod

=head2 datastore_add

=head3 PURPOSE



=head3 PARAMETERS

=over

=back

=head3 RETURNS

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

=head3 TEST COVERAGE

=cut

sub datastore_add {
    &Log::debug("Starting Datastore::datastore_add sub");
    &Log::debug("Finishing Datastore::datastore_add sub");
    return 1;
}

=pod

=head2 datastore_delete

=head3 PURPOSE



=head3 PARAMETERS

=over

=back

=head3 RETURNS

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

=head3 TEST COVERAGE

=cut

sub datastore_delete {
    &Log::debug("Starting Datastore::datastore_delete sub");
    &Log::debug("Finishing Datastore::datastore_delete sub");
    return 1;
}

=pod

=head2 datastore_list

=head3 PURPOSE



=head3 PARAMETERS

=over

=back

=head3 RETURNS

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

=head3 TEST COVERAGE

=cut

sub datastore_list {
    &Log::debug("Starting Datastore::datastore_list sub");
    &Log::debug("Finishing Datastore::datastore_list sub");
    return 1;
}

=pod

=head2 datastore_info

=head3 PURPOSE


=head3 PARAMETERS

=over

=back

=head3 RETURNS

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

=head3 TEST COVERAGE

=cut

sub datastore_info {
    &Log::debug("Starting Datastore::datastore_info sub");
    &Log::debug("Finishing Datastore::datastore_info sub");
    return 1;
}

1
