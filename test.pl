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
    diag('Test Base modules');

    use_ok('Base::entity');
    use_ok('Base::datastore');
    use_ok('Base::ticket');
    use_ok('Base::kayako');
    use_ok('Base::bugzilla');
    use_ok('Base::admin');
    use_ok('Base::misc');

    diag('Test BB modules');

    use_ok('BB::Log');
    use_ok('BB::Error');
    use_ok('BB::Support');
    use_ok('BB::Misc');

    diag('Test Pod2wiki module');

    use_ok('Pod::Simple::Wiki::Dokuwiki');
}

diag('Documentation tests');

ok( -e $FindBin::Bin . "/doc/main.pod", "Main.pod exists");

diag('Support.pm sub test');

ok( ref(&Support::get_keys("agents")) eq 'ARRAY', 'get_keys returned array' );
throws_ok { &Support::get_keys('TEST') } 'Template::Status', 'get_keys throws exception';

ok( ref( &Support::get_key_info('template','scb_342')) eq 'HASH', 'get_key_info returned hash' );
throws_ok { &Support::get_key_info('TEST', 'TEST') } 'Template::Status', 'get_key_info throws exception for bad map';
throws_ok { &Support::get_key_info('template', 'TEST') } 'Template::Status', 'get_key_info throws exception for bad key';

ok( ref(\&Support::get_key_value('agents','s4mur4i','mac')) eq 'SCALAR', 'get_key_value returned scalar' );
throws_ok { &Support::get_key_value('TEST', 'TEST','TEST') } 'Template::Status', 'get_key_value throws exception for bad map';
throws_ok { &Support::get_key_value('agents', 'TEST','TEST') } 'Template::Status', 'get_key_value throws exception for bad key';
throws_ok { &Support::get_key_value('agents', 's4mur4i','TEST') } 'Template::Status', 'get_key_value throws exception for bad value';

diag('Misc.pm sub test');

ok ( &Misc::array_longest( ["t","te","test","tes" ]) eq 4, 'array_longest returned longest element');

like( &Misc::random_3digit, qr/^\d{1,3}$/, 'random_3digit gave correct random number');

like( &Misc::generate_mac('s4mur4i'), qr/^([0-9A-F]{2}:){5}[0-9A-F]{2}$/, 'generate_mac gave a valid mac address' );

like( &Misc::increment_mac('00:00:00:00:00:00'), qr/^(00:){5}01$/, 'increment_mac gave a valid mac address' );
throws_ok { &Misc::increment_mac('00:00:00:FF:FF:FF') } 'Entity::Mac', 'increment_mac throws exception';

ok( ref( &Misc::vmname_splitter('TEST')) eq 'HASH',  'vmname_splitter returns hash');
my %hash = (ticket => 'unknown', username => 'unknown', uniq => 'unknown', family => 'unknown', version => 'unknown', lang => 'unknown', arch => 'unknown', type => 'unknown');
is_deeply( &Misc::vmname_splitter('TEST'), \%hash, 'vmname_splitter returned hash for unknown name');
%hash = (ticket => 'ticket', username => 'username', uniq => '1', family => 'xcb', version => '123', lang => 'en', arch => 'x64', type => 'xcb');
is_deeply( &Misc::vmname_splitter('ticket-username-xcb_123-1'), \%hash, 'vmname_splitter returned hash for xcb name');
%hash = (ticket => 'ticket', username => 'username', uniq => '123', family => 'win', version => '2008r2', lang => 'en', arch => 'x64', type => 'ent');
is_deeply( &Misc::vmname_splitter('ticket-username-win_2008r2_en_x64_ent-123'), \%hash, 'vmname_splitter returned hash for standard name');

ok( &Misc::increment_disk_name('/test/test/test/test.vmdk') eq "/test/test/test/test_1.vmdk", "increment_disk_name first increment" );
ok( &Misc::increment_disk_name('/test/test/test/test_6.vmdk') eq "/test/test/test/test_8.vmdk", "increment_disk_name skipping controller" );
throws_ok { &Misc::increment_disk_name('/test/test/test/test_15.vmdk') } 'Entity::NumException', 'increment_disk_name throws num exception at 15 scsi devices';

my @array = ( "datastore", "big/jew" , "dick.vmdk");
ok( ref(&Misc::filename_splitter("[datastore] big/jew/dick.vmdk")) eq 'ARRAY', 'filename_splitter returned array'  );
is_deeply( &Misc::filename_splitter("[datastore] big/jew/dick.vmdk"), \@array, 'filename_splitter returned correct information'  );
throws_ok{ &Misc::filename_splitter("I will be an exception") } 'Vcenter::Path', 'filename_splitter throws exception';

diag('Exception tests');
throws_ok { Entity::NumException->throw( error => 'test', entity => 'test', count => '0' ) } 'Entity', 'Entity Num Exception';
throws_ok { Entity::Status->throw( error => 'test', entity => 'test' ) } 'Entity', 'Entity Status Exception';
throws_ok { Entity::Auth->throw( error => 'test', entity => 'test', username => 'Joe', password => 'secret' ) } 'Entity', 'Entity Auth Exception';
throws_ok { Entity::TransferError->throw( error => 'test', entity => 'test', filename => '/some/path/to.me' ) } 'Entity', 'Entity Transfer Error Exception';
throws_ok { Entity::HWError->throw( error => 'test', entity => 'test', hw => 'dick' ) } 'Entity', 'Entity HW Error Exception';
throws_ok { Entity::Snapshot->throw( error => 'test', entity => 'test', snapshot => 'default' ) } 'Entity', 'Entity Snapshot Exception';
throws_ok { Entity::Mac->throw( error => 'test', entity => 'test', mac => '00:00:00:00:00:00' ) } 'Entity', 'Entity Mac Exception';
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
