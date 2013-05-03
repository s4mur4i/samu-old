package Support;

use strict;
use warnings;

BEGIN {
	use Exporter;
	our @ISA = qw(Exporter);
	our @EXPORT = qw( &test %template_hash );
	our @EXPORT_OK = qw( &test %template_hash );
}

our %template_hash = (
#	'scb-330' => 'Support/vm/templates/SCB/3.3/3.3.0',
	'scb-330' => 'Support/vm/templates/SCB/3.3/3.3.0.a',
	'scb-341' => 'Support/vm/templates/SCB/3.4/3.4.1',
);
sub test() {
	print "test\n";
}

#### We need to end with success
1
