#!/usr/bin/perl
use strict;
use warnings;
use 5.14.0;
use Test::More;
use Test::Exception;
use FindBin;
use lib "$FindBin::Bin/../../lib";

BEGIN {
    use_ok('BB::Support');
    use_ok('BB::Common');
}
isa_ok( &Support::get_keys("agents"), 'ARRAY', 'get_keys returned array' );
throws_ok { &Support::get_keys('TEST') } 'Template::Status', 'get_keys throws exception';

isa_ok( &Support::get_hash( 'template', 'scb_300' ), 'HASH', 'get_hash returned hash' );
throws_ok { &Support::get_hash( 'TEST', 'TEST' ) } 'Template::Status', 'get_key_info throws exception for bad map';
throws_ok { &Support::get_hash( 'template', 'TEST' ) } 'Template::Status', 'get_key_info throws exception for bad key';

ok( ref( \&Support::get_key_value( 'agents', 's4mur4i', 'mac' ) ) eq 'SCALAR', 'get_key_value returned scalar' );
throws_ok { &Support::get_key_value( 'TEST', 'TEST', 'TEST' ) } 'Template::Status', 'get_key_value throws exception for bad map';
throws_ok { &Support::get_key_value( 'agents', 'TEST', 'TEST' ) } 'Template::Status', 'get_key_value throws exception for bad key';
throws_ok { &Support::get_key_value( 'agents', 's4mur4i', 'TEST' ) } 'Template::Status', 'get_key_value throws exception for bad value';

done_testing;

END {
}
