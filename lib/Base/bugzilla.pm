package bugzilla;

use strict;
use warnings;
use Base::misc;

my $help = 0;

=pod

=head1 bugzilla.pm

Subrutiones from Base/bugzilla.pm

=cut

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
            function        => \&info,
            vcenter_connect => 0,
            opts            => {
                ticket => {
                    type     => "=s",
                    help     => "The bugzilla ticket to list information about",
                    required => 1,
                    default  => "",
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

Main entry for Bugzilla functions

=head3 PARAMETERS

=over

=back

=head3 RETURNS

True on succcess

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

=head3 TEST COVERAGE

=cut

sub main {
    &Log::debug("Starting Bugzilla::main sub");
    &misc::option_parser( $module_opts, "main" );
    &Log::debug("Finishing Bugzilla:main sub");
    return 1;
}

=pod

=head2 info

=head3 PURPOSE

Information about bugzilla ticket

=head3 PARAMETERS

=over

=back

=head3 RETURNS

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

=head3 TEST COVERAGE

=cut

sub info {
    &Log::debug("Starting Bugzilla::info sub");
    print "Not implemented yet";
    &Log::debug("Finishing Bugzolla::info sub");
    return 1;
}

1
