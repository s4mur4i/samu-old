#!/usr/bin/perl
use strict;
use warnings;
use 5.14.0;
use Test::More;
use Test::Exception;
use FindBin;
use lib "$FindBin::Bin/../../lib";

BEGIN { use_ok('BB::VCenter'); use_ok('BB::Common'); }
&Opts::parse();
&Opts::validate();
&Util::connect();
isa_ok( &VCenter::service_content, 'ServiceContent', "Service content returns valid object" );
isa_ok( &VCenter::get_vim, 'Vim', "Get vim returns valid object" );
## Need to find method to test task object
#throws_ok { &VCenter::Task_Status( 'test' ) } 'TaskEr::NotDefined', 'Task_status returns exception if invalid task is given';
&Util::disconnect();
done_testing;
