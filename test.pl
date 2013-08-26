#!/usr/bin/perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More;
use Test::Exception;
use Data::Dumper;
use Scalar::Util qw(reftype);

BEGIN {
    ## Test Base modules

    use_ok('Base::entity');
    use_ok('Base::datastore');
    use_ok('Base::ticket');
    use_ok('Base::kayako');
    use_ok('Base::bugzilla');
    use_ok('Base::admin');
    use_ok('Base::misc');

    ## Test BB modules

    use_ok('BB::Log');
    use_ok('BB::Error');
    use_ok('BB::Support');

    ## Helper modules for testing
#    use_ok('Pod::Usage');
}

## Documentation tests
ok( -e $FindBin::Bin . "/doc/main.pod", "Main.pod exists");

## misc test
my $module_opts = {
        helper => 'AUTHOR',
        functions => {
        },
};
#ok(&misc::option_parser($module_opts, "TEST") );

## support test
## get_keys
ok( ref(&Support::get_keys("agents")) eq 'ARRAY', 'get_keys returned array' );
throws_ok { &Support::get_keys('TEST') } 'Template::Status', 'get_keys throws exception';
## get_key_info
ok( ref( &Support::get_key_info('template','scb_342')) eq 'HASH', 'get_key_info returned hash' );
throws_ok { &Support::get_key_info('TEST', 'TEST') } 'Template::Status', 'get_key_info throws exception for bad map';
throws_ok { &Support::get_key_info('template', 'TEST') } 'Template::Status', 'get_key_info throws exception for bad key';
## get_key_value
ok( ref(\&Support::get_key_value('agents','s4mur4i','mac')) eq 'SCALAR', 'get_key_value returned scalar' );
throws_ok { &Support::get_key_value('TEST', 'TEST','TEST') } 'Template::Status', 'get_key_value throws exception for bad map';
throws_ok { &Support::get_key_value('agents', 'TEST','TEST') } 'Template::Status', 'get_key_value throws exception for bad key';
throws_ok { &Support::get_key_value('agents', 's4mur4i','TEST') } 'Template::Status', 'get_key_value throws exception for bad value';

## Exception tests
throws_ok { Entity::NumException->throw( error => 'test', entity => 'test', count => '0' ) } 'Entity', 'Entity Num Exception';
throws_ok { Entity::Status->throw( error => 'test', entity => 'test' ) } 'Entity', 'Entity Status Exception';
throws_ok { Entity::Auth->throw( error => 'test', entity => 'test', username => 'Joe', password => 'secret' ) } 'Entity', 'Entity Auth Exception';
throws_ok { Entity::TransferError->throw( error => 'test', entity => 'test', filename => '/some/path/to.me' ) } 'Entity', 'Entity Transfer Error Exception';
throws_ok { Entity::HWError->throw( error => 'test', entity => 'test', hw => 'dick' ) } 'Entity', 'Entity HW Error Exception';
throws_ok { Entity::Snapshot->throw( error => 'test', entity => 'test', snapshot => 'default' ) } 'Entity', 'Entity Snapshot Exception';
throws_ok { Vcenter::ServiceContent->throw( error => 'test' ) } 'Vcenter', 'Vcenter Service Content Exception';
throws_ok { Vcenter::Path->throw( error => 'test', path => '/path/to/inventory' ) } 'Vcenter', 'Vcenter Path Exception';
throws_ok { Template::Status->throw( error => 'test', template => 'test' ) } 'Template', 'Template Status Exception';
throws_ok { Template::Error->throw( error => 'test', template => 'test' ) } 'Template', 'Template Error Exception';
throws_ok { Connection::Connect->throw( error => 'test', type => 'test', dest => 'test' ) } 'Connection', 'Connection Connect Exception';
throws_ok { Task::NotDefined->throw( error => 'test' ) } 'Task', 'Task NotDefined Exception';
throws_ok { Task::Error->throw( error => 'test', detail => 'test', fault => 'test' ) } 'Task', 'Task Error Exception';

### Summary
## Until we know how many tests we are going to run, there should be no number reported
#done_testing(11);

__END__

=head1 Name

    test.pl

=head1 Description

    This script is used to test functionality of the jew script and backend modules
