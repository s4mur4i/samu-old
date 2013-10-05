package Error;

use strict;
use warnings;

use Data::Dumper;
use Exception::Class (
    'BaseException',

    ## Base Classes
    'Entity' => {
        isa    => 'BaseException',
        fields => ['entity'],
    },
    'Template' => {
        isa    => 'BaseException',
        fields => ['template'],
    },
    'TaskEr'     => { isa => 'BaseException', },
    'Connection' => { isa => 'BaseException', },
    'Vcenter'    => { isa => 'BaseException', },

    ## Entity Exceptions
    'Entity::NumException' => {
        isa         => 'Entity',
        description => 'Entity number not expected number',
        fields      => ['count'],
    },
    'Entity::Status' => {
        isa         => 'Entity',
        description => 'Entity Exists or does not exist',
    },
    'Entity::Auth' => {
        isa         => 'Entity',
        description => 'Could not Authenticate with guest',
        fields      => [ 'username', 'password' ],
    },
    'Entity::TransferError' => {
        isa         => 'Entity',
        description => 'Error happened trying to transfer file',
        fields      => ['filename'],
    },
    'Entity::HWError' => {
        isa         => 'Entity',
        description => 'HW reconfigure error',
        fields      => ['hw'],
    },
    'Entity::Snapshot' => {
        isa         => 'Entity',
        description => 'Snapshot Error',
        fields      => ['snapshot'],
    },
    'Entity::Mac' => {
        isa         => 'Entity',
        description => 'There was a problem with a mac',
        fields      => ['mac'],
    },

    ## Vcenter Exceptions

    'Vcenter::ServiceContent' => {
        isa         => 'Vcenter',
        description => 'Could not retrieve Service Content object',
    },
    'Vcenter::Path' => {
        isa         => 'Vcenter',
        description => 'Path to entity Error',
        fields      => ['path'],
    },
    'Vcenter::Opts' => {
        isa         => 'Vcenter',
        description => 'Requested opt is invalid',
        fields      => ['opt'],
    },
    'Vcenter::Module' => {
        isa         => 'Vcenter',
        description => 'Requested Module cannot be loaded',
        fields      => ['module'],
    },

     ## Template Exceptions
    'Template::Status' => {
        isa         => 'Template',
        description => 'Template does not exist',
    },
    'Template::Error' => {
        isa         => 'Template',
        description => 'Error with tempalte',
    },

    ## Connection Exceptions
    'Connection::Connect' => {
        isa         => 'Connection',
        description => 'Connection to some backend failed',
        fields      => [ 'type', 'dest' ],
    },

    ## Task Exceptions
    'TaskEr::NotDefined' => {
        isa         => 'TaskEr',
        description => 'No task reference returned',
    },
    'TaskEr::Error' => {
        isa         => 'TaskEr',
        description => 'Task had an error',
        fields      => [ 'detail', 'fault' ],
    },
);

BEGIN {
    use Exporter;
    our @ISA    = qw( Exporter );
    our @EXPORT = qw( &test &catch_ex );
}

use overload
  '""'     => sub { $_[0]->as_string },
  'bool'   => sub { 1 },
  fallback => 1;

#tested
sub catch_ex {
    my ($ex) = @_;
    &Log::debug2( "Dumping exception:" . Dumper($ex) );
    &Log::debug("Invoking Error:catch_ex sub");
    ## Entity Exceptions
    if ( $ex->isa('Entity::NumException') ) {
        &Log::critical( "Desc=>'"
              . $ex->error
              . "',entity=>'"
              . $ex->entity
              . "',count=>'"
              . $ex->count
              . "'" );
    }
    elsif ( $ex->isa('Entity::Status') ) {
        &Log::critical(
            "Desc=>'" . $ex->error . "',entity=>'" . $ex->entity . "'" );
    }
    elsif ( $ex->isa('Entity::Auth') ) {
        &Log::critical( "Desc=>'"
              . $ex->error
              . "',entity=>'"
              . $ex->entity
              . "',user=>'"
              . $ex->username
              . "',pass=>'"
              . $ex->password
              . "'" );
    }
    elsif ( $ex->isa('Entity::TransferError') ) {
        &Log::critical(
            "Desc=>'" . $ex->error . "',entity=>'" . $ex->entity . "'" );
    }
    elsif ( $ex->isa('Entity::HWError') ) {
        &Log::critical( "Desc=>'"
              . $ex->error
              . "',entity=>'"
              . $ex->entity
              . "',hw=>'"
              . $ex->hw
              . "'" );
    }
    elsif ( $ex->isa('Entity::Snapshot') ) {
        &Log::critical( "Desc=>'"
              . $ex->error
              . "',entity=>'"
              . $ex->entity
              . "',snapshot=>'"
              . $ex->snapshot
              . "'" );
    }
    elsif ( $ex->isa('Entity::Mac') ) {
        &Log::critical( "Desc=>'"
              . $ex->error
              . "',entity=>'"
              . $ex->entity
              . "',mac=>'"
              . $ex->mac
              . "'" );
    }
    elsif ( $ex->isa('Vcenter::ServiceContent') ) {
        &Log::critical( "Desc=>'" . $ex->error . "'" );
    }
    elsif ( $ex->isa('Vcenter::Path') ) {
        &Log::critical(
            "Desc=>'" . $ex->error . "',path=>'" . $ex->path . "'" );
    }
    elsif ( $ex->isa('Vcenter::Opts') ) {
        &Log::critical( "Desc=>'" . $ex->error . "',opt=>'" . $ex->opt . "'" );
    }
    elsif ( $ex->isa('Vcenter::Module') ) {
        &Log::critical(
            "Desc=>'" . $ex->error . "',module=>'" . $ex->module . "'" );
    }
    elsif ( $ex->isa('Connection::Connect') ) {
        &Log::critical( "Desc=>'"
              . $ex->error
              . "',type=>'"
              . $ex->type
              . "',dest=>'"
              . $ex->dest
              . "'" );
    }
    elsif ( $ex->isa('Template::Status') ) {
        &Log::critical(
            "Desc=>'" . $ex->error . "',template=>'" . $ex->template . "'" );
    }
    elsif ( $ex->isa('Template::Error') ) {
        &Log::critical(
            "Desc=>'" . $ex->error . "',template=>'" . $ex->template . "'" );
    }
    elsif ( $ex->isa('TaskEr::NotDefined') ) {
        &Log::critical( "Desc=>'" . $ex->error . "'" );
    }
    elsif ( $ex->isa('TaskEr::Error') ) {
        &Log::critical( "Desc=>'"
              . $ex->error
              . "',detail=>'"
              . $ex->detail
              . "',fault=>'"
              . $ex->fault
              . "'" );
    }
    elsif ( $ex->isa('Exception::Class') ) {
        &Log::debug("This is an unimplemented exception.");
        &Log::critical("Cannot understand the object, throwing dump");
        &Log::critical( "Information:" . Dumper($ex) );
    }
    else {
        &Log::info("This is an unkown error. Dumping information");
        &Log::critical("I'm blue and I'm a WTF.....");
        &Log::critical( "Information:" . Dumper($ex) );
    }
    &Log::debug("catch_ex sub is completed");
    return 1;
}

#### We need to end with success
1
