#!/usr/bin/perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use lib '/usr/lib/vmware-vcli/apps';
use SDK::Vcenter;
use VMware::VICommon;
use VMware::VIRuntime;
my %opts = (
	vmname => {
		type => '=s',
		help => 'Vm to promote disk',
		required => 1,
	},
);
Opts::add_options(%opts);
Opts::parse();
Opts::validate();
my $username = Opts::get_option('username');
my $password = Opts::get_option('password');
my $url = Opts::get_option('url');
my $vmname = Opts::get_option('vmname');
Util::connect( $url, $username, $password );
my $view = Vim::find_entity_view(view_type=>'VirtualMachine',filter=>{name=>$vmname});
if ( !defined($view) ) {
	print "Cannot find vm\n";
	exit 2;
}
$view->PromoteDisks_Task(unlink=>1);
my ($ticket, $username, $family, $version, $lang, $arch, $type , $uniq) = &Misc::vmname_splitter($vmname);
&Vcenter::create_folder($ticket,"vm");
my $folder_view = Vim::find_entity_view(view_type=>'Folder',filter=>{name=>$ticket});
$folder_view->MoveIntoFolder_Task(list=>[$view]);
# Disconnect from the server
Util::disconnect();
# To mitigate SSL warnings by default
BEGIN {
	$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
}
