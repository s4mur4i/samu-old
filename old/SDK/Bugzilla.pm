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
	Util::trace( 4, "Starting Bugzilla::bugzilla_status sub, ticket=>'$ticket'\n" );
	my $url = "http://bugzilla.balabit/bugzilla-3.0/show_bug.cgi?id=$ticket";
	my $content;
	for my $line ( split qr/\R/, get( $url ) ) {
		( $content ) = $line =~ /\s*<span id="static_bug_status">(\w+)/ if ( $line =~ /<span id="static_bug_status">/ ) ;
	}
	if ( defined( $content ) ) {
		Util::trace( 4, "Finishing Bugzilla::bugzilla_status sub\n" );
		return $content;
	} else {
		Util::trace( 4, "Finishing Bugzilla::bugzilla_status sub\n" );
		return "Unknown";
	}
}

sub test() {
	Util::trace( 4, "Starting Bugzilla::test sub\n" );
        Util::trace( 0, "Bugzilla module test sub\n" );
	Util::trace( 4, "Finishing Bugzilla::test sub\n" );
}

#### We need to end with success
1
