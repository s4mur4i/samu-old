package datastore;

use strict;
use warnings;
use Base::misc;

my $help = 0;

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
    &Log::debug("Starting Datastore::main sub");
    &misc::option_parser( $module_opts, "main" );
    &Log::debug("Finishing Datastore::main sub");
    return 1;
}

=pod

=head1 datastore_add

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

sub datastore_add {
    &Log::debug("Starting Datastore::datastore_add sub");
    &Log::debug("Finishing Datastore::datastore_add sub");
    return 1;
}

=pod

=head1 datastore_delete

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

sub datastore_delete {
    &Log::debug("Starting Datastore::datastore_delete sub");
    &Log::debug("Finishing Datastore::datastore_delete sub");
    return 1;
}

=pod

=head1 datastore_list

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

sub datastore_list {
    &Log::debug("Starting Datastore::datastore_list sub");
    &Log::debug("Finishing Datastore::datastore_list sub");
    return 1;
}


=pod

=head1 datastore_info

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

sub datastore_info {
    &Log::debug("Starting Datastore::datastore_info sub");
    &Log::debug("Finishing Datastore::datastore_info sub");
    return 1;
}

1;
__END__
