package Bugzilla;

use strict;
use warnings;
use LWP::Simple;

BEGIN {
    use Exporter;
    our @ISA    = qw( Exporter );
    our @EXPORT = qw( );
}

=pod

=head1 bugzilla_status

=head2 PURPOSE

Retrieve Status of bugzilla

=head2 PARAMETERS

=back

=item ticket

The Bugzilla ticket number to retrieve

=over

=head2 RETURNS

Unknown if no information is returned, else the returned value

=head2 DESCRIPTION

Sub retrieves the bugzilla ticket status with regexp matching the html page.

=head2 THROWS

=head2 COMMENTS

Very fragile, the backend can cange any time. Need to upgrade bugzilla so we can do API calls

=head2 SEE ALSO

=cut

sub bugzilla_status {
    my ($ticket) = @_;
    &Log::debug("Starting Bugzilla::bugzilla_status sub");
    &Log::debug1("Opts are: ticket=>'$ticket'");
    my $url = "http://bugzilla.balabit/bugzilla-3.0/show_bug.cgi?id=$ticket";
    &Log::debug1("URL is:'$url'");
    my $content;
    for my $line ( split qr/\R/, get($url) ) {
        &Log::debug2("Line is:'$line'");
        ($content) = $line =~ /\s*<span id="static_bug_status">(\w+)/
          if ( $line =~ /<span id="static_bug_status">/ );
    }
    if ( !defined($content) ) {
        &Log::debug("Content could not be understood returning Unknown");
        $content = "Unknown";
    }
    &Log::debug(
        "Finishing Bugzilla::bugzilla_status sub");
    &Log::debug("Return=>'$content'");
    return $content;
}

1
