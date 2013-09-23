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

BEGIN {
    &Opts::parse();
    &Opts::validate();
    &Util::connect();
}
ok( \&admin::templates, "Admin templates sub ran succesfully" );
output_like( \&admin::templates, qr/^Name:'[^ ']*'\s*Path:'[^ ']*'/, qr/^$/, "Output is a valid templates output" );
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
    is( $T_vm->name, &VCenter::path2name(&Support::get_key_value( 'template', $os_temp, 'path' )), "Reverse lookup for path" );
    diag("Only one entity exists from vmname");
    isa_ok( &Guest::entity_name_view( $T_vm->name, 'VirtualMachine' ), 'VirtualMachine', "Moref is returned by known object" );
    isa_ok( &Guest::entity_full_view( $T_vm->name, 'VirtualMachine' ), 'VirtualMachine', "Moref is returned by known object" );
    isa_ok( &Guest::entity_full_view( $T_vm->name, 'VirtualMachine', 'name' ), 'VirtualMachine', "Moref is returned by known object" );
    my $memory = Vim::find_entity_view( view_type  => 'VirtualMachine', properties => ['summary.config.memorySizeMB'], filter => { name => $T_vm->name });
    ok( &Guest::entity_property_view( $T_vm->name, 'VirtualMachine', 'summary.config.memorySizeMB' ) eq $memory->get_property('summary.config.memorySizeMB'), "vm_memory returned correct value" );
    my $cpu = Vim::find_entity_view( view_type  => 'VirtualMachine', properties => ['summary.config.numCpu'], filter => { name => $T_vm->name });
    ok( &Guest::entity_property_view( $T_vm->name, 'VirtualMachine', 'summary.config.numCpu' ) eq $cpu->get_property('summary.config.numCpu'), "vm_numcpu returned correct value" );
    diag("Testing altername");
    is( &Guest::get_altername($T_vm->name), '', "Altername is default for " . $T_vm->name );
    like( &Guest::get_annotation_key( $T_vm->name, "alternateName" ), qr/^\d+$/, "Annotation_key returns digit" );
}
done_testing;
END {
    &Util::disconnect();
}
