#!/usr/bin/perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use SDK::Vcenter;
use VMware::VIRuntime;
my %opts = (
	 name => {
                type => "=s",
                help => "Folder to list. If not give all folders will be listed.",
                required => 1,
        },
	parent => {
		type => "=s",
                help => "Folder to list. If not give all folders will be listed.",
                required => 0,
	},
);
Opts::add_options(%opts);
Opts::parse();
Opts::validate();
my $username = Opts::get_option('username');
my $password = Opts::get_option('password');
my $url = Opts::get_option('url');
my $name = Opts::get_option('name');
my $parent = Opts::get_option('parent');
Util::connect( $url, $username, $password );
eval {
if (!defined($parent)) {
	$parent = "vm";
} else {
	if (!&Vcenter::exists_folder($parent)) {
		Util::trace( 0, "Parent is not found.\n" );
		exit 3;
	}
}
&Vcenter::create_folder($name,$parent);
};
if ($@) { &Error::catch_ex( $@ ); }
# Disconnect from the server
Util::disconnect();
# To mitigate SSL warnings by default
BEGIN {
	$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
}
