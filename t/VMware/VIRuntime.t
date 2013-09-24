#!/usr/bin/perl
use strict;
use warnings;
use 5.14.0;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../../vmware_lib";

BEGIN { use_ok('VMware::VIRuntime'); }
diag("Dummy module for useing VMware::VIRuntime module");
done_testing;
