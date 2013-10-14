package Output;

use strict;
use warnings;
use Text::Table;
use Class::CSV;

=pod

=head1 Output.pm

Subroutines from BB/Output.pm

=cut

my $csv;
my $tbh;

=pod

=head1 create_table

=head2 PURPOSE

Creates main table object

=head2 PARAMETERS

=over

=back

=head2 RETURNS

True on success

=head2 DESCRIPTION

=head2 THROWS

=head2 COMMENTS

=head2 SEE ALSO

=cut

sub create_table {
    &Log::debug("Starting Output::create_table sub");
    if ( !defined( $tbh ) ) {
        &Log::debug("Creating table object");
        $tbh = Text::Table->new();
    } else {
        &Log::warning("Table object already created");
    }
    &Log::debug("Finishing Output::create_table sub");
    return 1;
}

=pod

=head1 create_csv

=head2 PURPOSE

Create CSV main object

=head2 PARAMETERS

=over

=item header

array ref to title names

=back

=head2 RETURNS

True on success

=head2 DESCRIPTION

=head2 THROWS

=head2 COMMENTS

=head2 SEE ALSO

=cut

sub create_csv {
    my ( $header ) =@_;
    &Log::debug("Starting Output::create_csv sub");
    if ( !defined( $csv ) ) {
        &Log::debug("Creating csv object");
        $csv = Class::CSV->new(fields =>$header);
    } else {
        &Log::warning("CSV object already created");
    }
    &Log::debug("Finishing Output::create_csv sub");
    return 1;
}

=pod

=head1 add_row

=head2 PURPOSE

Adds a row to the table/csv main object

=head2 PARAMETERS

=over

=item row

Array ref with the information

=back

=head2 RETURNS

True on success

=head2 DESCRIPTION

=head2 THROWS

=head2 COMMENTS

=head2 SEE ALSO

=cut

sub add_row {
    my ($row) = @_;
    &Log::debug("Starting Output::create_table sub");
    &Log::dumpobj( "row", $row);
    if ( defined($tbh) ) {
        &Log::debug("Adding row to table");
        $tbh->add(@$row);
    } elsif(defined $csv) {
        &Log::debug("Adding row to csv");
        $csv->add_line($row);
    }
    &Log::debug("Finishing Output::add_row sub");
    return 1;
}

=pod

=head1 print

=head2 PURPOSE

Prints the information of the handler object

=head2 PARAMETERS

=over

=back

=head2 RETURNS

True on success

=head2 DESCRIPTION

=head2 THROWS

=head2 COMMENTS

=head2 SEE ALSO

=cut

sub print {
    &Log::debug("Starting Output::print sub");
    if ( defined($tbh) ) {
        &Log::debug("Printing from table");
        $tbh->load;
        print $tbh;
    } elsif(defined $csv) {
        &Log::debug("Printing from csv");
        $csv->print;
    }
    &Log::debug("Finishing Output::print sub");
    return 1;
}

1
