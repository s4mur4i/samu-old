#!/usr/bin/perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use SDK::Misc;
use VMware::VICommon;
use VMware::VIRuntime;
use Data::Dumper;

my %opts = (
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
my ( $ticket, $username, $family, $version, $lang, $arch, $type , $uniq ) = &Misc::vmname_splitter($vmname);
if ( defined($type) and $type eq 'win' ) {
	print "Installing puppet in windows environment\n";
	my $workdir='c:\\';
	my $env='PATH=C:\windows\system32';
	my $prog='c:\WINDOWS\system32\msiexec.exe';
        my $arg = '/qb /l*v C:\install.txt /i "\\\\share.balabit\install\Windows\MS_Server_Applications\puppet\puppet-2.7.12.msi" PUPPET_MASTER_SERVER=puppet.ittest.balabit INSTALLDIR=C:\puppet';
        &Support::runCommandInGuest( $vmname, $prog, $arg, $env, $workdir);
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
