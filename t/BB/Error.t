#!/usr/bin/perl
use strict;
use warnings;
use 5.14.0;
use Test::More;
use Test::Exception;
use Test::Output;
use FindBin;
use lib "$FindBin::Bin/../../lib";
use BB::Log;
use Data::Dumper;

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
diag("Testing Catch");
eval { Entity->throw( error => 'test', entity => 'test' ); };
my $ex = $@;
#Error.pm s4mur4i [ERROR] [3686]: I'm blue and I'm a WTF.....;
combined_like( sub{ &Error::catch_ex($ex)}, qr/Error.pm\s[^ ]*\s\[ERROR\]\s\[\d*\]:\sI'm blue and I'm a WTF.....;/, "Entity Base exception" );
eval { Template->throw( error => 'test', template => 'test' ); };
$ex = $@;
combined_like( sub{ &Error::catch_ex($ex)}, qr/Error.pm\s[^ ]*\s\[ERROR\]\s\[\d*\]:\sI'm blue and I'm a WTF.....;/, "Template Base exception" );
eval { Task->throw( error => 'test' ); };
$ex = $@;
combined_like( sub{ &Error::catch_ex($ex)}, qr/Error.pm\s[^ ]*\s\[ERROR\]\s\[\d*\]:\sI'm blue and I'm a WTF.....;/, "Task Base exception" );
eval { Connection->throw( error => 'test' ); };
$ex = $@;
combined_like( sub{ &Error::catch_ex($ex)}, qr/Error.pm\s[^ ]*\s\[ERROR\]\s\[\d*\]:\sI'm blue and I'm a WTF.....;/, "Connection Base exception" );
eval { Vcenter->throw( error => 'test' ); };
$ex = $@;
combined_like( sub{ &Error::catch_ex($ex)}, qr/Error.pm\s[^ ]*\s\[ERROR\]\s\[\d*\]:\sI'm blue and I'm a WTF.....;/, "Vcenter Base exception" );
eval { Entity::NumException->throw( error => 'test', entity => 'test', count => '1'); };
$ex = $@;
stderr_like( sub{ &Error::catch_ex($ex)}, qr/Error.pm\s[^ ]*\s\[ERROR\]\s\[\d*\]:\sDesc=>'test',entity=>'test',count=>'1';/, "Entity Numcount exception output" );
eval { Entity::Status->throw( error => 'test', entity => 'test'); };
$ex = $@;
stderr_like( sub{ &Error::catch_ex($ex)}, qr/Error.pm\s[^ ]*\s\[ERROR\]\s\[\d*\]:\sDesc=>'test',entity=>'test';/, "Entity Status exception output" );
eval { Entity::Auth->throw( error => 'test', entity => 'test', username => 'me', password => 'bebebebe'); };
$ex = $@;
stderr_like( sub{ &Error::catch_ex($ex)}, qr/Error.pm\s[^ ]*\s\[ERROR\]\s\[\d*\]:\sDesc=>'test',entity=>'test',user=>'me',pass=>'bebebebe';/, "Entity Auth exception output" );
eval { Entity::TransferError->throw( error => 'test', entity => 'test'); };
$ex = $@;
stderr_like( sub{ &Error::catch_ex($ex)}, qr/Error.pm\s[^ ]*\s\[ERROR\]\s\[\d*\]:\sDesc=>'test',entity=>'test';/, "Entity TransferError exception output" );
eval { Entity::HWError->throw( error => 'test', entity => 'test', hw => 'dick'); };
$ex = $@;
stderr_like( sub{ &Error::catch_ex($ex)}, qr/Error.pm\s[^ ]*\s\[ERROR\]\s\[\d*\]:\sDesc=>'test',entity=>'test',hw=>'dick';/, "Entity HWError exception output" );
eval { Entity::Snapshot->throw( error => 'test', entity => 'test', snapshot => 'test'); };
$ex = $@;
stderr_like( sub{ &Error::catch_ex($ex)}, qr/Error.pm\s[^ ]*\s\[ERROR\]\s\[\d*\]:\sDesc=>'test',entity=>'test',snapshot=>'test';/, "Entity Snapshot exception output" );
eval { Entity::Mac->throw( error => 'test', entity => 'test', mac => 'test'); };
$ex = $@;
stderr_like( sub{ &Error::catch_ex($ex)}, qr/Error.pm\s[^ ]*\s\[ERROR\]\s\[\d*\]:\sDesc=>'test',entity=>'test',mac=>'test';/, "Entity Mac exception output" );
eval { Vcenter::ServiceContent->throw( error => 'test'); };
$ex = $@;
stderr_like( sub{ &Error::catch_ex($ex)}, qr/Error.pm\s[^ ]*\s\[ERROR\]\s\[\d*\]:\sDesc=>'test';/, "Vcenter ServiceContent exception output" );
eval { Vcenter::Path->throw( error => 'test',path => '/some/path/to/gold'); };
$ex = $@;
stderr_like( sub{ &Error::catch_ex($ex)}, qr@Error.pm\s[^ ]*\s\[ERROR\]\s\[\d*\]:\sDesc=>'test',path=>'/some/path/to/gold';@, "Vcenter Path exception output" );
eval { Connection::Connect->throw( error => 'test', type => 'test', dest => 'test'); };
$ex = $@;
stderr_like( sub{ &Error::catch_ex($ex)}, qr@Error.pm\s[^ ]*\s\[ERROR\]\s\[\d*\]:\sDesc=>'test',type=>'test',dest=>'test';@, "Connection Connect exception output" );
eval { Template::Status->throw( error => 'test',template => 'template'); };
$ex = $@;
stderr_like( sub{ &Error::catch_ex($ex)}, qr@Error.pm\s[^ ]*\s\[ERROR\]\s\[\d*\]:\sDesc=>'test',template=>'template';@, "Template Status exception output" );
eval { Template::Error->throw( error => 'test',template => 'template'); };
$ex = $@;
stderr_like( sub{ &Error::catch_ex($ex)}, qr@Error.pm\s[^ ]*\s\[ERROR\]\s\[\d*\]:\sDesc=>'test',template=>'template';@, "Template Error exception output" );
eval { Task::NotDefined->throw( error => 'test'); };
$ex = $@;
stderr_like( sub{ &Error::catch_ex($ex)}, qr/Error.pm\s[^ ]*\s\[ERROR\]\s\[\d*\]:\sDesc=>'test';/, "Task NotDefined exception output" );
eval { Task::Error->throw( error => 'test',fault => 'test',detail=>'test'); };
$ex = $@;
stderr_like( sub{ &Error::catch_ex($ex)}, qr@Error.pm\s[^ ]*\s\[ERROR\]\s\[\d*\]:\sDesc=>'test',detail=>'test',fault=>'test';@, "Task Error exception output" );
eval { BaseException->throw( ); };
$ex = $@;
combined_like( sub{ &Error::catch_ex($ex)}, qr/Error.pm\s[^ ]*\s\[ERROR\]\s\[\d*\]:\sI'm blue and I'm a WTF.....;/, "Base Exception for all exceptions output" );
done_testing();
