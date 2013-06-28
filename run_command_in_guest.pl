#!/usr/bin/perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use lib '/usr/lib/vmware-vcli/apps';
use SDK::Support;
use SDK::GuestInternal;
use VMware::VICommon;
use VMware::VIRuntime;
use Data::Dumper;

my %opts = (
	vmname => {
                type => "=s",
                help => "Name of VM",
                required => 1,
        },
	guestusername => {
                type => "=s",
                help => "Username for guest OS",
                required => 0,
        },
	guestpassword => {
                type => "=s",
                help => "Password for guest OS",
                required => 0,
        },
	prog => {
                type => "=s",
                help => "Full path for program to run",
                required => 1,
        },
	prog_arg => {
                type => "=s",
                help => "Arguments to program",
                required => 0,
        },
	workdir => {
                type => "=s",
                help => "Working directory to run program in",
                required => 0,
        },
	env => {
                type => "=s",
                help => "ENV settings for program",
                required => 0,
        },

);
Opts::add_options(%opts);
Opts::parse();
Opts::validate();
my $username = Opts::get_option('username');
my $password = Opts::get_option('password');
my $datacenter = Opts::get_option('datacenter');
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
my $guestProgSpec = GuestProgramSpec->new(workingDirectory=> Opts::get_option('workdir'), programPath=> Opts::get_option('prog'), arguments => Opts::get_option('prog_arg'), envVariables =>[Opts::get_option('env')]);
print Dumper($guestProgSpec);
my $pid;
eval {
	$pid = $guestProcMan->StartProgramInGuest(vm=>$vm_view, auth=>$guestCreds, spec=>$guestProgSpec);
};
if($@) {
                die( "Error: " . $@);
}
print "Pid is $pid\n";

# Disconnect from the server
Util::disconnect();
# To mitigate SSL warnings by default
BEGIN {
	$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
}
