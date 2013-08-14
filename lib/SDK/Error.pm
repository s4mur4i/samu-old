package Error;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin";
use Exception::Class (
	'BaseException',

	'NoEntityException' => {
		isa => 'BaseException',
		description => 'No entity found with requested name',
		fields => [ 'entity' ],
	},
);

BEGIN {
	use Exporter;
	our @ISA = qw( Exporter );
	our @EXPORT = qw( &test );
}


## Functionality test sub
sub test( ) {
	print "Error module test sub\n";
}

#### We need to end with success
1
