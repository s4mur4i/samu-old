#!/usr/bin/perl

use strict;
use warnings;
#use diagnostics;
use FindBin;
use lib "$FindBin::Bin/lib";
use lib '/usr/lib/vmware-vcli/apps';
use Support;
use VMware::VICommon;
use VMware::VIRuntime;
use Data::Dumper;

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
	vmname => {
                type => "=s",
                help => "Name of VM",
                required => 1,
        },
);
Opts::add_options(%opts);
Opts::parse();
Opts::validate();
my $username = Opts::get_option('username');
my $password = Opts::get_option('password');
my $vmname = Opts::get_option('vmname');
my $url = Opts::get_option('url');
Util::connect( $url, $username, $password );
my $type;
#puppet-s4mur4i-win_2003_en_x64_ent-476
if ( $vmname =~ /^[^-]*-[^-]*-[^-]*-\d{3}$/ ) {
	my ($os) = $vmname =~ m/^[^-]*-[^-]*-([^-]*)-\d{3}$/ ;
	$type=$Support::template_hash{$os}{'os'};
} else {
	print "Regex matched an OS, but no template found to it.\n";
	exit 1;
}
if ( $type eq 'win' ) {
	print "Installing puppet in windows environment\n";
	my $dirname = dirname($0);
	print "Mounting share.\n";
	my $prog='c:\WINDOWS\system32\net.exe';
	my $arg='use T: \\\\share.balabit\install';
	my $workdir='c:\\';
	my $env='PATH=C:\windows\system32';
	print "My prog:'" . $prog . "'\n";
	print "My args:'" . $arg . "'\n";
	#$vmname, $prog, $prog_arg, $env, $workdir, $guestusername, $guestpassword
	&Support::runCommandInGuest( $vmname, $prog, $arg, $env, $workdir);
	#my $result = `$dirname/runcommandinguest.pl --vmname $vmname --prog '$prog' --prog_arg '$arg'`;
	#print "$result\n";
#	`$dirname/runcommandinguest.pl --vmname $vmname --prog "msiexec.exe" --workdir "c:\\" --prog_arg "/qn /l*v c:\\windows\\temp\\install.txt /i '\\\\share.balabit\\install\\Windows\\MS_Server_Applications\\puppet\\puppet-2.7.12.msi' PUPPET_MASTER_SERVER=puppet.ittest.balabit INSTALLDIR=C:\\Program Files\\Puppet" --env "PATH=c:\\Windows\\System32"`;
} else {
	print "Not yet supported platform.\n";
	exit 1;
}

# Disconnect from the server
Util::disconnect();
# To mitigate SSL warnings by default
BEGIN {
	$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
}
