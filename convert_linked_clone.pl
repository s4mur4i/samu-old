#!/usr/bin/perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use SDK::Support;
use VMware::VICommon;
use VMware::VIRuntime;
use Data::Dumper;

print "Experimental script...not working yet...\n";

my %opts = (
	username => {
		type => "=s",
		variable => "VI_USERNAME",
		help => "Username to ESX",
		required => 0,
	},
	password => {
		type => "=s",
		variable => "VI_PASSWORD",
		help => "Password to ESX",
		required => 0,
	},
	server => {
		type => "=s",
		variable => "VI_SERVER",
		help => "ESX hostname or IP address",
		default => "vcenter.ittest.balabit",
		required => 0,
	},
	protocol => {
		type => "=s",
		variable => "VI_PROTOCOL",
		help => "http or https, that is the question",
		default => "https",
		required => 0,
	},
	portnumber => {
		type => "=i",
		variable => "VI_PROTOCOL",
		help => "ESX port for connection",
		default => "443",
		required => 0,
	},
	url => {
		type => "=s",
		variable => "VI_URL",
		help => "URL for ESX",
		required => 0,
	},
	datacenter => {
		type => "=s",
		help => "Datacenter",
		default => "support",
		required => 0,
	},
	vm => {
		type => "=s",
                help => "VM to convert",
                required => 1,
	},
);
Opts::add_options(%opts);
Opts::parse();
Opts::validate();
my $username = Opts::get_option('username');
my $password = Opts::get_option('password');
my $datacenter = Opts::get_option('datacenter');
my $url = Opts::get_option('url');
Util::connect( $url, $username, $password );
my $vm = Opts::get_option('vm');
my ($ticket) = $vm =~ /^([^-]*)-.*$/;
print "Ticket: $ticket\n";
$vm = Vim::find_entity_view(view_type=>'VirtualMachine',filter=>{name=>$vm});
if (!defined($vm)) {
	print "Machine was not found.\n";
	exit 1;
}
my $priority = VirtualMachineMovePriority->new('defaultPriority');
print "Consolidating disk.\n";
eval {
	#$vm->MigrateVM(priority=>$priority);
	$vm->ConsolidateVMDisks_Task();
};
if ($@) {
        if (ref($@) eq 'SoapFault') {
                if (ref($@->detail) eq 'FileFault') {
                        Util::trace(0, "\nFailed to access the virtual " ." machine files\n");
                } else {
                        Util::trace (0, "Fault" . $@ . "\n"   );
                        print Dumper($@);
                }
                exit 1;
        } else {
                Util::trace (0, "Fault" . $@ . "\n"   );
                        print Dumper($@);
                exit 1;
        }
}
my $folder = Vim::find_entity_view(view_type=>'Folder',filter=>{name=>$ticket});
print "Moving Machine out of linked clone folder.\n";
if ( defined($folder)) {
## MoveIntoFolder_Task to new folder
	eval {
		$folder->MoveIntoFolder_Task(list=>[$vm]);
	};
	if ($@) {
		if (ref($@) eq 'SoapFault') {
			if (ref($@->detail) eq 'FileFault') {
				Util::trace(0, "\nFailed to access the virtual " ." machine files\n");
			} else {
				Util::trace (0, "Fault" . $@ . "\n"   );
				print Dumper($@);
			}
			exit 1;
		} else {
			Util::trace (0, "Fault" . $@ . "\n"   );
				print Dumper($@);
			exit 1;
		}
	}
} else {
	print "Need to create folder.\n";
	my $parent_folder = Vim::find_entity_view(view_type=>'Folder',filter=>{name=>$username});
	my $folder = $parent_folder->CreateFolder(name=>$ticket);
	$folder = Vim::get_view( mo_ref => $folder );
	eval {
                $folder->MoveIntoFolder_Task(list=>[$vm]);
        };
        if ($@) {
                if (ref($@) eq 'SoapFault') {
                        if (ref($@->detail) eq 'FileFault') {
                                Util::trace(0, "\nFailed to access the virtual " ." machine files\n");
                        } else {
                                Util::trace (0, "Fault" . $@ . "\n"   );
                                print Dumper($@);
                        }
                        exit 1;
                } else {
                        Util::trace (0, "Fault" . $@ . "\n"   );
                                print Dumper($@);
                        exit 1;
                }
        }
}
# Disconnect from the server
Util::disconnect();
# To mitigate SSL warnings by default
BEGIN {
	$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
}
