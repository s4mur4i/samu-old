package Bugzilla;

use strict;
use warnings;
use LWP::Simple;

BEGIN {
        use Exporter;
        our @ISA = qw( Exporter );
        our @EXPORT = qw( );
}

sub bugzilla_status {
    my ( $ticket ) = @_;
    &Log::debug("Starting Bugzilla::bugzilla_status sub, ticket=>'$ticket'");
    my $url = "http://bugzilla.balabit/bugzilla-3.0/show_bug.cgi?id=$ticket";
    my $content;
    for my $line ( split qr/\R/, get( $url ) ) {
        ( $content ) = $line =~ /\s*<span id="static_bug_status">(\w+)/ if ( $line =~ /<span id="static_bug_status">/ ) ;
    }
    if ( !defined( $content ) ) {
        &Log::debug("Content could not be understood returning Unknown");
        $content = "Unknown";
    }
    &Log::debug("Finishing Bugzilla::bugzilla_status sub, returning=>''$content");
    return $content;
}

#### We need to end with success
1
