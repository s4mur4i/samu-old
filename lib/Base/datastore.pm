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
        list => {
            function        => \&datastore_list,
            vcenter_connect => 1,
            opts            => {
                output => {
                    type     => "=s",
                    help     => "Output type, table/csv",
                    default  => "table",
                    required => 0,
                },
                noheader => {
                    type     => "",
                    help     => "Should header information be printed",
                    required => 0,
                },
                datacenter => {
                    type => "=s",
                    help => "Datacenter",
                    default => "Support",
                    required => 0,
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

=head2 datastore_list

=head3 PURPOSE

List information about attached datastores

=head3 PARAMETERS

=over

=item output

Type of output. csv/ table

=item noheader

Should header row be printed

=item datacenter

Which  datacenter should we list datastores of

=back

=head3 RETURNS

true on success

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

=head3 TEST COVERAGE

=cut

sub datastore_list {
    &Log::debug("Starting Datastore::datastore_list sub");
    my @titles = (qw(Name Accessible Capacity(GB) Free(GB) Free(%) Uncommited(GB) Overcommit(%) Type Alarm AttachedVms));
    &Output::option_parser( \@titles );
    my $datacenter = &Guest::entity_property_view( &Opts::get_option('datacenter'),'Datacenter' , 'datastore');
    for my $datastore ( @{ $datacenter->{datastore}}) {
        &Output::add_row( &VCenter::datastore_info($datastore)  );
    }
    &Output::print;
    &Log::debug("Finishing Datastore::datastore_list sub");
    return 1;
}

1
