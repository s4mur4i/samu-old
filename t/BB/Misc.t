#!/usr/bin/perl
use strict;
use warnings;
use 5.14.0;
use Test::More;
use Test::Exception;
use FindBin;
use lib "$FindBin::Bin/../../lib";

BEGIN{ use_ok('BB::Misc'); use_ok('BB::Common'); }

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

like( &Misc::generate_vmname("ticket", "joe", "os_temp"), qr/^ticket-joe-os_temp-\d{1,3}$/, 'generate_vmname returned a valid vmname' );

done_testing;
