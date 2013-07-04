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
use LWP::Simple;

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
my $vmname = Opts::get_option('vmname');
my $url = Opts::get_option('url');
Util::connect( $url, $username, $password );
my $vm_view = Vim::find_entity_view(view_type=>'VirtualMachine',filter=>{name=>$vmname});
my $guestusername;
my $guestpassword;
my ($ticket, $gusername, $family, $version, $lang, $arch, $type , $uniq) = &Misc::vmname_splitter($vmname);
my $os = "${family}_${version}_${lang}_${arch}_${type}";
if ( defined($uniq)  ) {
  if ( defined($Support::template_hash{$os})) {
        $guestusername=$Support::template_hash{$os}{'username'};
        $guestpassword=$Support::template_hash{$os}{'password'};
  } else {
        print "Regex matched an OS, but no template found to it os=> '$os'\n";
  }
} else {
        print "Vmname not standard name=> '$vmname'\n";
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
