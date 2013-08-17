package Error;

use strict;
use warnings;
use lib "$FindBin::Bin";
#use Try::Tiny;
use Scalar::Util qw( blessed );
use Data::Dumper;
use Switch;
use Exception::Class (
	'SDK::Error::BaseException',
	## Base Classes
	'SDK::Error::Entity' => {
		isa => 'SDK::Error::BaseException',
	}
	'SDK::Error::Task' => {
		isa => 'SDK::Error::BaseException',
	}
	## Entity Exceptions
	'SDK::Error::Entity::NumException' => {
		isa => 'SDK::Error::Entity',
		description => 'Entity number not expected number',
		fields => [ 'entity', 'count' ],
	},

	'SDK::Error::Entity::Exists' => {
		isa => 'SDK::Error::Entity',
		description => 'After operation Entity still exists'.
		fields => [ 'entity' ],
	},
	## Task Exceptions
	'SDK::Error::Task::NotDefined' => {
		isa => 'SDK::Error::Task',
		description => 'No task reference returned',
	},
	'SDK::Error::Task::Error' => {
		isa => 'SDK::Error::Task',
		description => 'Task had an error',
		fields => [ 'detail', 'fault' ],
	},
);

BEGIN {
	use Exporter;
	our @ISA = qw( Exporter );
	our @EXPORT = qw( &test &catch_ex );
}

use overload '""' => sub {$_[0]->as_string}, 'bool' => sub {1}, fallback => 1;

sub catch_ex {
	my ( $ex ) = @_;
	## Entity
	if ( $ex->isa( 'SDK::Error::Entity::NumException' ) ) {
		print "Desc=>'" . $ex->error . "',entity=>'" . $ex->entity ."',count=>'" . $ex->count . "'\n";
	}
	if ( $ex->isa( 'SDK::Error::Entity::Exists' ) ) {
		print "Desc=>'" . $ex->error . "',entity=>'" . $ex->entity . "'\n";
	}
	## Task
	if ( $ex->isa( 'SDK::Error::Task::NotDefined' ) ) {
		print "Desc=>" . $ex->error . "\n";
	}
	if ( $ex->isa( 'SDK::Error::Task::Error' ) ) {
		print "Desc=>" . $ex->error . ",detail=>" . $ex->detail . ",fault=>" . $ex->fault . "\n";
	}
	## Other
	if ( $ex->isa('SDK::Error::BaseException') ) {
		print "Desc=>'" . $ex->error . "\n";
	}
	if ( $ex->isa( 'Exception::Class' ) ) {
		print "Cannot understand the object, throwing dump.\n";
		print Dumper($ex);
	}
	exit;
}

## Functionality test sub
sub test( ) {
	print "Error module test sub\n";
}

#### We need to end with success
1
