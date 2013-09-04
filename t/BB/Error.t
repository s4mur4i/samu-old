#!/usr/bin/perl
use strict;
use warnings;
use 5.14.0;
use Test::More;
use Test::Exception;
use FindBin;
use lib "$FindBin::Bin/../../lib";

BEGIN { use_ok('BB::Error'); }

throws_ok {
    Entity::NumException->throw(
        error  => 'test',
        entity => 'test',
        count  => '0'
    );
}
'Entity', 'Entity Num Exception';
throws_ok { Entity::Status->throw( error => 'test', entity => 'test' ) }
'Entity', 'Entity Status Exception';
throws_ok {
    Entity::Auth->throw(
        error    => 'test',
        entity   => 'test',
        username => 'Joe',
        password => 'secret'
    );
}
'Entity', 'Entity Auth Exception';
throws_ok {
    Entity::TransferError->throw(
        error    => 'test',
        entity   => 'test',
        filename => '/some/path/to.me'
    );
}
'Entity', 'Entity Transfer Error Exception';
throws_ok {
    Entity::HWError->throw( error => 'test', entity => 'test', hw => 'dick' );
}
'Entity', 'Entity HW Error Exception';
throws_ok {
    Entity::Snapshot->throw(
        error    => 'test',
        entity   => 'test',
        snapshot => 'default'
    );
}
'Entity', 'Entity Snapshot Exception';
throws_ok {
    Entity::Mac->throw(
        error  => 'test',
        entity => 'test',
        mac    => '00:00:00:00:00:00'
    );
}
'Entity', 'Entity Mac Exception';
throws_ok { Vcenter::ServiceContent->throw( error => 'test' ) } 'Vcenter',
  'Vcenter Service Content Exception';
throws_ok {
    Vcenter::Path->throw( error => 'test', path => '/path/to/inventory' );
}
'Vcenter', 'Vcenter Path Exception';
throws_ok { Template::Status->throw( error => 'test', template => 'test' ) }
'Template', 'Template Status Exception';
throws_ok { Template::Error->throw( error => 'test', template => 'test' ) }
'Template', 'Template Error Exception';
throws_ok {
    Connection::Connect->throw(
        error => 'test',
        type  => 'test',
        dest  => 'test'
    );
}
'Connection', 'Connection Connect Exception';
throws_ok { Task::NotDefined->throw( error => 'test' ) } 'Task',
  'Task NotDefined Exception';
throws_ok {
    Task::Error->throw( error => 'test', detail => 'test', fault => 'test' );
}
'Task', 'Task Error Exception';
done_testing();
