#!/usr/bin/perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use SDK::Support;
use SDK::GuestInternal;
use VMware::VIRuntime;
use Data::Dumper;

my %opts = (
	vmname => {
                type => "=s",
                help => "Name of VM",
                required => 1,
        },
	pid => {
		type => "=s",
                help => "pid if requested program",
                required => 0,
	},
	guestusername => {
                type => "=s",
                help => "Username to use to log into machine",
                required => 0,
        },
	guestpassword => {
                type => "=s",
                help => "Password to use to log into machine",
                required => 0,
        },

);
Opts::add_options(%opts);
Opts::parse();
Opts::validate();
my $username = Opts::get_option('username');
my $password = Opts::get_option('password');
my $pid = Opts::get_option('pid');
my $vmname = Opts::get_option('vmname');
my $url = Opts::get_option('url');
Util::connect( $url, $username, $password );
my $vm_view = Vim::find_entity_view(view_type=>'VirtualMachine',filter=>{name=>$vmname});
my $guestusername;
my $guestpassword;
if ( $vmname =~ /^[^-]*-[^-]*-[^-]*-\d{3}$/ ) {
  my ($os) = $vmname =~ m/^[^-]*-[^-]*-([^-]*)-\d{3}$/ ;
  if ( defined($Support::template_hash{$os})) {
	$guestusername=$Support::template_hash{$os}{'username'};
	$guestpassword=$Support::template_hash{$os}{'password'};
  } else {
	print "Regex matched an OS, but no template found to it os=> '$os'\n";
  }
} else {
	if ( !defined( Opts::get_option( 'guestusername' ) ) and !defined( Opts::get_option( 'guestpassword' ) ) ) {
		print "VMname not matched standard, and not usernames defined.\n";
		exit 1;
	}
}
if ( defined(Opts::get_option('guestusername')) && defined(Opts::get_option('guestpassword'))) {
		$guestusername=Opts::get_option('guestusername');
		$guestpassword=Opts::get_option('guestpassword');
}
print "username=> '$guestusername' password=> '$guestpassword' vmname=> '" . defined($vm_view) . "'\n";
if ( (!defined($guestusername)) || (!defined($guestpassword)) || (!defined($vm_view)) ) {
	die("Cannot run. some paramter failed to be parsed or guessed... or both: username=> '$guestusername' password=> '$guestpassword' vmname=> '" . defined($vm_view) . "'");
}
my $guestOpMgr = Vim::get_view(mo_ref => Vim::get_service_content()->guestOperationsManager);
my $guestCreds = &GuestInternal::acquireGuestAuth($guestOpMgr,$vm_view,$guestusername,$guestpassword);
my $guestProcMan = Vim::get_view(mo_ref => $guestOpMgr->processManager);
my @pids;
eval {
	if (defined($pid)) {
	@pids = $guestProcMan->ListProcessesInGuest(vm=>$vm_view, auth=>$guestCreds, pids=>[$pid]);
	} else {
	@pids =$guestProcMan->ListProcessesInGuest(vm=>$vm_view, auth=>$guestCreds);
	}
};
if($@) {
                die( "Error: " . $@);
}
print Dumper(@pids);
# Disconnect from the server
Util::disconnect();
# To mitigate SSL warnings by default
BEGIN {
	$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
}
