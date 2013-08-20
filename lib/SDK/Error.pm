package Error;

use strict;
use warnings;
use lib "$FindBin::Bin";
use Scalar::Util qw( blessed );
use Data::Dumper;
use Switch;
use Exception::Class (
	'SDK::Error::BaseException',
	## Base Classes
	'SDK::Error::Entity' => {
		isa => 'SDK::Error::BaseException',
	},
	'SDK::Error::Task' => {
		isa => 'SDK::Error::BaseException',
	},
	'SDK::Error::Template' => {
		isa => 'SDK::Error::BaseException',
	},
	'SDK::Error::DBI' => {
		isa => 'SDK::Error::BaseException',
	},
	## Entity Exceptions
	'SDK::Error::Entity::NumException' => {
		isa => 'SDK::Error::Entity',
		description => 'Entity number not expected number',
		fields => [ 'entity', 'count' ],
	},
	'SDK::Error::Entity::Exists' => {
		isa => 'SDK::Error::Entity',
		description => 'After operation Entity still exists',
		fields => [ 'entity' ],
	},
	'SDK::Error::Entity::ServiceContent' => {
		isa => 'SDK::Error::Entity',
		description => 'Could not retrieve Service Content object',
	},
	'SDK::Error::Entity::Path' => {
		isa => 'SDK::Error::Entity',
		description => 'Path to entity Error',
		fields => [ 'path' ],
	},
	'SDK::Error::Entity::Auth' => {
		isa => 'SDK::Error::Entity',
		description => 'Could not Authenticate with guest',
		fields => [ 'entity', 'username', 'password' ],
	},
	'SDK::Error::Entity::TransferError' => {
		isa => 'SDK::Error::Entity',
		description => 'Error happened trying to transfer file',
	},
	'SDK::Error::Entity::HWError' => {
		isa => 'SDK::Error::Entity',
		description => 'HW reconfigure error',
		fields => [ 'entity', 'hw' ],
	},
	'SDK::Error::Entity::Snapshot' => {
		isa => 'SDK::Error::Entity',
		description => 'Snapshot Error',
	},
	## Template Exceptions
	'SDK::Error::Template::Exists' => {
		isa => 'SDK::Error::Template',
		description => 'Template does not exist',
		fields => [ 'template' ],
	},
	'SDK::Error::Template::Error' => {
		isa => 'SDK::Error::Template',
		description => 'Error with tempalte',
		fields => [ 'template' ],
	},
	## DBI Exceptions
	'SDK::Error::DBI::Connect' => {
		isa => 'SDK::Error::DBI',
		description => 'DBI connection failed',
		fields => [ 'worker' ],
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
	Util::trace( 4, "Starting Error:catch_ex sub\n" );
	if ( $ex->isa( 'SDK::Error::Entity::NumException' ) ) {
		Util::trace( 0, "Desc=>'" . $ex->error . "',entity=>'" . $ex->entity ."',count=>'" . $ex->count . "'\n" );
	} elsif ( $ex->isa( 'SDK::Error::Entity::Exists' ) ) {
		Util::trace( 0, "Desc=>'" . $ex->error . "',entity=>'" . $ex->entity . "'\n" );
	} elsif ( $ex->isa( 'SDK::Error::Task::NotDefined' ) ) {
		Util::trace( 0, "Desc=>" . $ex->error . "\n" );
	} elsif ( $ex->isa( 'SDK::Error::Entity::ServiceContent' ) ) {
		Util::trace( 0, "Desc=>" . $ex->error . "\n" );
	} elsif ( $ex->isa( 'SDK::Error::Entity::Path' ) ) {
		Util::trace( 0, "Desc=>" . $ex->error . ",path=>" . $ex->path . "\n" );
	} elsif ( $ex->isa( 'SDK::Error::Entity::Auth' ) ) {
		Util::trace( 0, "Desc=>" . $ex->error . ",entity=>" . $ex->entity . ",user=>" . $ex->username . ",pass=>" . $ex->password . "\n" );
	} elsif ( $ex->isa( 'SDK::Error::Entity::TransferError' ) ) {
		Util::trace( 0, "Desc=>" . $ex->error . "\n" );
	} elsif ( $ex->isa( 'SDK::Error::Entity::HWError' ) ) {
		Util::trace( 0, "Desc=>" . $ex->error . ",entity=>" . $ex->entity . ",hw=>" . $ex->hw . "\n" );
	} elsif ( $ex->isa( 'SDK::Error::Entity::Snapshot' ) ) {
		Util::trace( 0, "Desc=>" . $ex->error . "\n" );
	} elsif ( $ex->isa( 'SDK::Error::Task::Error' ) ) {
		Util::trace( 0, "Desc=>" . $ex->error . ",detail=>" . $ex->detail . ",fault=>" . $ex->fault . "\n" );
	} elsif ( $ex->isa( 'SDK::Error::Template::Exists' ) ) {
		Util::trace( 0, "Desc=>" . $ex->error . ",template=>" .$ex->template . "\n" );
	} elsif ( $ex->isa( 'SDK::Error::Template::Error' ) ) {
		Util::trace( 0, "Desc=>" . $ex->error . ",template=>" . $ex->template .  "\n" );
	} elsif ( $ex->isa('SDK::Error::BaseException') ) {
		Util::trace( 0, "Desc=>'" . $ex->error . "\n" );
	} elsif ( $ex->isa( 'Exception::Class' ) ) {
		Util::trace( 0, "Cannot understand the object, throwing dump.\n" );
		print Dumper($ex);
	} else {
		Util::trace( 0, "I'm blue and I'm a WTF....." );
	}
	Util::trace( 4, "Finished Error::catch_ex sub\n" );
	exit;
}

## Functionality test sub
sub test( ) {
	Util::trace( 4, "Starting Error:test sub\n" );
	Util::trace( 0, "Error module test sub\n" );
	Util::trace( 4, "Finished Error::test sub\n" );
}

#### We need to end with success
1
