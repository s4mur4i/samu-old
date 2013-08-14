package Error;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin";
use Data::Dumper;
use Switch;
use Exception::Class (
	'BaseException',

	'EntityNumException' => {
		isa => 'BaseException',
		description => 'Entity number not expected number ',
		fields => [ 'entity', 'count' ],
	},
);

BEGIN {
	use Exporter;
	our @ISA = qw( Exporter );
	our @EXPORT = qw( &test &catch );
}

use overload '""' => sub {$_[0]->as_string}, 'bool' => sub {1}, fallback => 1;

sub catch {
	my ( $ex ) = @_;
	die $ex unless blessed $ex && $ex->can('rethrow');
	print Dumper($ex);
	if ( $ex->isa( 'EntityNumException' ) ) {
		print "Desc =>'" . $ex->error . "',entity=>'" . $ex->entity ."',count=>'" . $ex->count . "'\n";
		exit;
	}
	if ( $ex->isa('BaseException') ) {
		print "Desc =>'" . $ex->error . "\n";
	}
	if ( $ex->isa( 'Exception::Class' ) ) {
		print "Cannot understand the object, throwing dump.\n";
		print Dumper($ex);
		exit;
	}
}

## Functionality test sub
sub test( ) {
	print "Error module test sub\n";
}

#### We need to end with success
1
