package bugzilla;

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

### subs

our $module_opts = {
    helper    => 'BUGZILLA',
    functions => {
        info => {
            function => \&info,
            vcenter_connect => 0,
            opts     => {
                ticket => {
                    type     => "=s",
                    help     => "The bugzilla ticket to list information about",
                    required => 1,
                },
            },
        },
    },
};

=pod

=head1 main

=head2 PURPOSE

Main entry for Bugzilla functions

=head2 PARAMETERS

=back

=over

=head2 RETURNS

True on succcess

=head2 DESCRIPTION

=head2 THROWS

=head2 COMMENTS

=head2 SEE ALSO

=cut

sub main {
    &Log::debug("Starting Bugzilla::main sub");
    &misc::option_parser( $module_opts, "main" );
    &Log::debug("Finishing Bugzilla:main sub");
    return 1;
}

=pod

=head1 info

=head2 PURPOSE

Information about bugzilla ticket

=head2 PARAMETERS

=back

=over

=head2 RETURNS

=head2 DESCRIPTION

=head2 THROWS

=head2 COMMENTS

=head2 SEE ALSO

=cut

sub info {
    &Log::debug("Starting Bugzilla::info sub");
    print "Not implemented yet";
    &Log::debug("Finishing Bugzolla::info sub");
    return 1;
}

1;
