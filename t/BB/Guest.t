#!/usr/bin/perl
use strict;
use warnings;
use 5.14.0;
use Test::More;
use Test::Exception;
use FindBin;
use lib "$FindBin::Bin/../../lib";

BEGIN { use_ok('BB::Guest'); use_ok('BB::Common'); }
&Opts::parse();
&Opts::validate();
&Util::connect();
diag("Testing entity_name_view sub");
throws_ok { &Guest::entity_name_view( 'fiszem_faszom', 'VirtualMachine' ) }
'Entity::NumException', "Throws exception by no found entity";
diag("Testing entity_full_view sub");
throws_ok { &Guest::entity_full_view( 'fiszem_faszom', 'VirtualMachine' ) }
'Entity::NumException', "Throws exception by no found entity";
diag("Testing entity_property_view sub");
throws_ok {
    &Guest::entity_property_view( 'fiszem_faszom', 'VirtualMachine', 'name' );
}
'Entity::NumException', "Throws exception by no found entity";
throws_ok { &Guest::get_altername('fiszem_faszom') } 'Entity::NumException',
  "altername throws exception";
throws_ok { &Guest::get_annotation_key( 'fiszem_faszom', 'test' ) }
'Entity::NumException', "annotation_key throws exception";
&Util::disconnect();
done_testing;
