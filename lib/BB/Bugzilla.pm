package Bugzilla;

use strict;
use warnings;
use LWP::Simple;

BEGIN {
    use Exporter;
    our @ISA    = qw( Exporter );
    our @EXPORT = qw( );
    &Log::debug1("Loaded module Bugzilla");
}

#tested
sub bugzilla_status {
    my ($ticket) = @_;
    &Log::debug("Starting Bugzilla::bugzilla_status sub, ticket=>'$ticket'");
    my $url = "http://bugzilla.balabit/bugzilla-3.0/show_bug.cgi?id=$ticket";
    &Log::debug1("URL is:'$url'");
    my $content;
    for my $line ( split qr/\R/, get($url) ) {
        &Log::debug2("Line is:'$line'");
        ($content) = $line =~ /\s*<span id="static_bug_status">(\w+)/
          if ( $line =~ /<span id="static_bug_status">/ );
        &Log::debug2("Content is : $content");
    }
    if ( !defined($content) ) {
        &Log::debug("Content could not be understood returning Unknown");
        $content = "Unknown";
    }
    &Log::debug(
        "Finishing Bugzilla::bugzilla_status sub, returning=>'$content'");
    return $content;
}

#### We need to end with success
1
