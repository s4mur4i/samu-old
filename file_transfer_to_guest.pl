#!/usr/bin/perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use lib '/usr/lib/vmware-vcli/apps';
use SDK::Support;
use SDK::GuestInternal;
use SDK::Misc;
use VMware::VICommon;
use VMware::VIRuntime;
use Data::Dumper;
use HTTP::Request;
use LWP::UserAgent;

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
                help => "Path to file to upload on guest",
                required => 1,
	},
	dest => {
		type => "=s",
		help => "Upload destination file.",
		required =>1,
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
### Fixme : maybe give some options possibility
my $fileattr = GuestFileAttributes->new();
my $path = Opts::get_option('path');
my $dest= Opts::get_option('dest');
my $size = -s $path;
## Fixme hardwired but we can allow setting this variable
my $overwrite = 0;
my $transferinfo;
eval {
        $transferinfo = $guestFileMan->InitiateFileTransferToGuest(vm=>$vm_view, auth=>$guestCreds, guestFilePath=>$dest, fileAttributes=>$fileattr, fileSize=>$size, overwrite=>$overwrite);
};
if($@) {
                die( "Error: " . $@);
}
#print Dumper($transferinfo);
print "Information about file: $path \n";
print "Size of file: $size bytes\n";
#my $req = HTTP::Request->new("PUT", $transferinfo);
#print "req is $req\n";
my $ua  = LWP::UserAgent->new();
$ua->ssl_opts(verify_hostname=>0);
#my $req = HTTP::Request->new(PUT => $url, Content => $path );
open(my $fh, "<$path");
my $content = do{local $/; <$fh>} ;
my $req = $ua->put($transferinfo,Content => $content);
#print Dumper($req);
#my $response = $ua->request($req);
if ($req->is_success()) {
    print "OK: ", $req->content ."\n";
} else {
    print "Failed: ", $req->as_string . "\n";
}
# Disconnect from the server
Util::disconnect();
# To mitigate SSL warnings by default
BEGIN {
	$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
}
