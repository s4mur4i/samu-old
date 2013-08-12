#!/usr/bin/perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use SDK::Support;
use SDK::Misc;
use SDK::GuestInternal;
use VMware::VIRuntime;
use Data::Dumper;
# ./run_command_in_guest.pl --vmname s3 --guestusername root --guestpassword titkos --prog "/bin/echo" --prog_arg ' $test >anyad' --env "test=pinaPINA" --workdir "/tmp
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
                required => 1,
        },
	workdir => {
                type => "=s",
                help => "Working directory to run program in",
                required => 1,
        },
	env => {
                type => "=s",
                help => "ENV settings for program",
                required => 1,
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
my ($ticket, $username2, $family, $version, $lang, $arch, $type , $uniq) = &Misc::vmname_splitter($vmname);
my $os = "${family}_${version}_${lang}_${arch}_${type}";
if ( defined($Support::template_hash{$os})) {
	$guestusername=$Support::template_hash{$os}{'username'};
	$guestpassword=$Support::template_hash{$os}{'password'};
}
if ( defined(Opts::get_option('guestusername')) && defined(Opts::get_option('guestpassword'))) {
		$guestusername=Opts::get_option('guestusername');
		$guestpassword=Opts::get_option('guestpassword');
}
print "username=> '$guestusername' password=> '$guestpassword' vmname=> '" . defined($vm_view) . "'\n";
if ( (!defined($guestusername)) || (!defined($guestpassword)) || (!defined($vm_view)) ) {
	die("Cannot run. some paramter failed to be parsed or guessed... or both: username=> '$guestusername' password=> '$guestpassword' vmname=> '" . defined($vm_view) . "'");
}
my $prog = Opts::get_option('prog');
my $prog_arg = Opts::get_option('prog_arg');
my $env = Opts::get_option('env');
my $workdir = Opts::get_option('workdir');
my $pid = &GuestInternal::runCommandInGuest($vmname,$prog, $prog_arg, $env, $workdir, $guestusername, $guestpassword);
print "Pid is $pid\n";

# Disconnect from the server
Util::disconnect();
# To mitigate SSL warnings by default
BEGIN {
	$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
}
