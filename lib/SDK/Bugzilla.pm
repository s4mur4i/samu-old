package Bugzilla;

use strict;
use warnings;
use Data::Dumper;
use LWP::Simple;

BEGIN {
        use Exporter;
        our @ISA = qw( Exporter );
        our @EXPORT = qw( &test &bugzilla_status );
}

sub bugzilla_status {
	my ( $ticket ) = @_;
	my $url = "http://bugzilla.balabit/bugzilla-3.0/show_bug.cgi?id=$ticket";
	my $content;
	for my $line ( split qr/\R/, get( $url ) ) {
		( $content ) = $line =~ /\s*<span id="static_bug_status">(\w+)/ if ( $line =~ /<span id="static_bug_status">/ ) ;
	}
	return $content;

}

sub test() {
        print "Bugzilla module test sub\n";
}

#### We need to end with success
1
