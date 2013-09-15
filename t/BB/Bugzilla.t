#!/usr/bin/perl
use strict;
use warnings;
use 5.14.0;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../../lib";

BEGIN { use_ok('BB::Bugzilla'); use_ok('BB::Common'); }
is( &Bugzilla::bugzilla_status( 'test' ), 'Unknown', "Testing return of bugzilla_status of unknown ticket" );
is( &Bugzilla::bugzilla_status( 1 ), 'Unknown', "Testing return of bugzilla_status of ticket 1" );
is( &Bugzilla::bugzilla_status( 30000 ), 'CLOSED', "Testing return of bugzilla_status of ticket 30000" );
done_testing;
