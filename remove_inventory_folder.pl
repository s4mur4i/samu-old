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
	name => {
                type => "=s",
                help => "The folder to delete",
                required => 1,
        },
);
Opts::add_options(%opts);
Opts::parse();
Opts::validate();
my $username = Opts::get_option('username');
my $password = Opts::get_option('password');
my $url = Opts::get_option('url');
my $name = Opts::get_option('name');
Util::connect( $url, $username, $password );
if (&Vcenter::exists_folder($name)) {
        print "Folder exists, deleting\n";
        if (&Vcenter::check_if_empty_folder($name)) {
                &Vcenter::delete_folder($name);
        } else {
                print "Folder not empty. Clean up first\n";
        }
} else {
        print "Cannot find folder\n";
}
# Disconnect from the server
Util::disconnect();
# To mitigate SSL warnings by default
BEGIN {
	$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
}
