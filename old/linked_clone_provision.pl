#!/usr/bin/perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use SDK::Support;
use SDK::Vcenter;
use SDK::Misc;
use VMware::VIRuntime;
use Data::Dumper;


my $task = $template_mo_ref->CloneVM_Task(  folder => $dest_folder_view->{'mo_ref'}, name=> $vmname, spec=> $clone_spec);
&Vcenter::Task_getStatus($task);
Util::trace( 0, "===================================================================\n" );
Util::trace( 0, "Machine is provisioned.\n" );
Util::trace( 0, "Login: '" . $Support::template_hash{$os}{'username'} . "' / '" . $Support::template_hash{$os}{'password'} ."'\n" );
Util::trace( 0, "Unique name of vm: " . $vmname . "\n" );
