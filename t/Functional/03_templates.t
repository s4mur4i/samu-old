#!/usr/bin/perl
use strict;
use warnings;
use 5.14.0;
use Test::More;
use Test::Output;
use FindBin;
use lib "$FindBin::Bin/../../lib/";
use BB::Common;
use Base::admin;

&Opts::parse();
&Opts::validate();
&Util::connect();
ok( \&admin::templates, "Admin templates sub ran succesfully" );
stderr_like( \&admin::templates, qr/^admin.pm\s[^ ]*\s\[INFO\]\s\[\d*\]:\sName:'[^ ']*'\s*Path:'[^ ']*';/, "Output is a valid templates output" );
my $T_vms = Vim::find_entity_views( view_type => 'VirtualMachine', properties => [ 'name' ], filter => { name => qr/^T_/ } );
for my $T_vm ( @$T_vms) {
    diag("Testing " . $T_vm->name);
    my ($os_temp) = $T_vm->name =~ /^T_(.*)$/ ;
    diag("Extracted template name: $os_temp");
    ok( &Support::get_key_info( 'template', $os_temp ), "os_temp exists in template hash" );
    my @keys = qw(username password os path);
    for my $key (@keys) {
        isnt( &Support::get_key_value( 'template', $os_temp, $key ), undef, "Template $os_temp has default key $key defined" );
    }
    is( &VCenter::name2path( $T_vm->name ), &Support::get_key_value( 'template', $os_temp, 'path' ), "$os_temp path is same as in hash" );
}
&Util::disconnect();
done_testing;
