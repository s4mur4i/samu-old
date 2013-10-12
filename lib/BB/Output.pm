package Output;

use strict;
use warnings;
use Text::Table;
=pod

=head1 Output.pm

Subroutines from BB/Output.pm

=cut

my $csv;
my $tbh;

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

sub create_csv {
    &Log::debug("Starting Output::create_csv sub");
    &Log::debug("Finishing Output::create_csv sub");
    return 1;
}

sub add_row {
    my ($row) = @_;
    &Log::debug("Starting Output::create_table sub");
    &Log::dumpobj( "row", $row);
    if ( defined($tbh) ) {
        &Log::debug("Adding row to table");
        $tbh->add(@$row);
    } elsif(defined $csv) {
        &Log::debug("Adding row to csv");
    }
    &Log::debug("Finishing Output::add_row sub");
    return 1;
}

sub print {
    &Log::debug("Starting Output::print sub");
    if ( defined($tbh) ) {
        &Log::debug("Printing from table");
        $tbh->load;
        print $tbh;
    } elsif(defined $csv) {
        &Log::debug("Printing from csv");
    }
    &Log::debug("Finishing Output::print sub");
    return 1;
}

1
