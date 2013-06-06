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
#use HTTP::Request;
use LWP::Simple;

## Fixme need to refactor and put this sub in module
sub acquireGuestAuth {
        my ($gOpMgr,$vmview,$gu,$gp) = @_;

        my $authMgr = Vim::get_view(mo_ref => $gOpMgr->authManager);
        my $guestAuth = NamePasswordAuthentication->new(username => $gu, password => $gp, interactiveSession => 'false');

        eval {
                print "Validating guest credentials in " . $vmview->name . " ...\n";
                $authMgr->ValidateCredentialsInGuest(vm => $vmview, auth => $guestAuth);
        };
        if($@) {
                die( "Error: " . $@ . "\n");
        } else {
                print "Succesfully validated guest credentials!\n";
        }

        return $guestAuth;
}

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
	path => {
		type => "=s",
                help => "Path to file to download on guest",
                required => 1,
	},
	dest => {
		type => "=s",
		help => "Destination file to download file.",
		required =>0,
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
if ( $vmname =~ /^[^-]*-[^-*]-[^-]*-\d{3}$/ ) {
  my ($os) = $vmname =~ m/^[^-]*-[^-*]-([^-]*)-\d{3}$/ ;
  if ( defined($Support::template_hash{$os})) {
        #$source_temp = $Support::template_hash{$os}{'path'};
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
my $guestCreds = &acquireGuestAuth($guestOpMgr,$vm_view,$guestusername,$guestpassword);
my $guestFileMan = Vim::get_view(mo_ref => $guestOpMgr->fileManager);

my $path = Opts::get_option('path');
my $transferinfo;
eval {
        $transferinfo = $guestFileMan->InitiateFileTransferFromGuest(vm=>$vm_view, auth=>$guestCreds, guestFilePath=>$path);
};
if($@) {
                die( "Error: " . $@);
}
my $dest= Opts::get_option('dest');
#print Dumper($transferinfo);
print "Information about file: $path \n";
print "Size: " . $transferinfo->size. " bytes\n";
print "modification Time: " . $transferinfo->attributes->modificationTime . " and access Time : " .$transferinfo->attributes->accessTime . "\n" ;
if ( !defined($dest) ) {
	my $basename = basename($path);
	my $content = get($transferinfo->url);
	open(my $fh, ">/tmp/$basename");
	print $fh "$content";
	close($fh);
} else {
	print "Downloading file to: '$dest'\n";
	getstore($transferinfo->url,$dest);
}
# Disconnect from the server
Util::disconnect();
# To mitigate SSL warnings by default
BEGIN {
	$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
}
