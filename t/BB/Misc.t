#!/usr/bin/perl
use strict;
use warnings;
use 5.14.0;
use Test::More;
use Test::Exception;
use FindBin;
use lib "$FindBin::Bin/../../lib";
use Pod::Simple::Wiki::Dokuwiki;
use Test::Output;

BEGIN {
    use_ok('BB::Misc');
    use_ok('BB::Common');
    &Opts::parse();
    &Opts::validate();
    &Util::connect();
}

ok( &Misc::array_longest( [ "t", "te", "test", "tes" ] ) eq 4,
    'array_longest returned longest element' );

like( &Misc::random_3digit, qr/^\d{1,3}$/,
    'random_3digit gave correct random number' );

for my $key ( @{ &Support::get_keys('agents')} ) {
    like( &Misc::generate_mac($key), qr/^([0-9A-F]{2}:){5}[0-9A-F]{2}$/, "generate_mac gave a valid mac address for user $key");
}

like( &Misc::increment_mac('00:00:00:00:00:00'),
    qr/^(00:){5}01$/, 'increment_mac gave a valid mac address' );
throws_ok { &Misc::increment_mac('00:00:00:FF:FF:FF') } 'Entity::Mac',
  'increment_mac throws exception';

ok( ref( &Misc::vmname_splitter('TEST') ) eq 'HASH',
    'vmname_splitter returns hash' );
my %hash = (
    ticket   => 'unknown',
    username => 'unknown',
    uniq     => 'unknown',
    family   => 'unknown',
    version  => 'unknown',
    lang     => 'unknown',
    arch     => 'unknown',
    type     => 'unknown',
    template => 'unknown',
);
is_deeply( &Misc::vmname_splitter('TEST'),
    \%hash, 'vmname_splitter returned hash for unknown name' );
%hash = (
    ticket   => 'ticket',
    username => 'username',
    uniq     => '1',
    family   => 'xcb',
    version  => '123',
    lang     => 'en',
    arch     => 'x64',
    type     => 'xcb',
    template => 'xcb_123',
);
is_deeply( &Misc::vmname_splitter('ticket-username-xcb_123-1'),
    \%hash, 'vmname_splitter returned hash for xcb name' );
%hash = (
    ticket   => 'ticket',
    username => 'username',
    uniq     => '123',
    family   => 'win',
    version  => '2008r2',
    lang     => 'en',
    arch     => 'x64',
    type     => 'ent',
    template => 'win_2008r2_en_x64_ent',
);
is_deeply( &Misc::vmname_splitter('ticket-username-win_2008r2_en_x64_ent-123'),
    \%hash, 'vmname_splitter returned hash for standard name' );

ok(
    &Misc::increment_disk_name('/test/test/test/test.vmdk') eq
      "/test/test/test/test_1.vmdk",
    "increment_disk_name first increment"
);
ok(
    &Misc::increment_disk_name('/test/test/test/test_6.vmdk') eq
      "/test/test/test/test_8.vmdk",
    "increment_disk_name skipping controller"
);
throws_ok { &Misc::increment_disk_name('/test/test/test/test_15.vmdk') }
'Entity::NumException',
  'increment_disk_name throws num exception at 15 scsi devices';

my @array = ( "datastore", "big/jew", "dick.vmdk" );
ok(
    ref( &Misc::filename_splitter("[datastore] big/jew/dick.vmdk") ) eq 'ARRAY',
    'filename_splitter returned array'
);
is_deeply( &Misc::filename_splitter("[datastore] big/jew/dick.vmdk"),
    \@array, 'filename_splitter returned correct information' );
throws_ok { &Misc::filename_splitter("I will be an exception") } 'Vcenter::Path', 'filename_splitter throws exception';

like(
    &Misc::generate_vmname( "ticket", "joe", "os_temp" ),
    qr/^ticket-joe-os_temp-\d{1,3}$/,
    'generate_vmname returned a valid vmname'
);
my $username = &Opts::get_option('username');
isa_ok( &Misc::user_ticket_list($username), 'HASH', "user_ticket list returned hash" );

use Data::Dumper;
my $hash = &Misc::ticket_list;
isa_ok( &Misc::ticket_list, 'HASH', "ticket list returned hash");
for my $key ( keys %$hash) {
    isa_ok( &Support::get_hash( 'agents', $hash->{$key} ), 'HASH', "get_hash returned hash for user $hash->{$key}" );
}

#FIXME generate_macs, a mac should be taken and a further macs arround that pool should be requested

throws_ok { &Misc::pod2wiki("/test/test") } 'Connection::Connect', 'pod2wiki throws exception if file not found';
my $out = &Misc::pod2wiki("$FindBin::Bin/../../lib/BB/Misc.pm");
stdout_like( sub{ print $out; }, qr/^\s*===== Misc.pm =====/, "pod2wiki returned text as expected" );
done_testing;

END {
    &Util::disconnect();
}
