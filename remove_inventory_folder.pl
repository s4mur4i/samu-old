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
eval {
if (&Vcenter::exists_folder($name)) {
        Util::trace( 0, "Folder exists, deleting\n" );
        if (&Vcenter::check_if_empty_folder($name)) {
                &Vcenter::delete_folder($name);
        } else {
                Util::trace( 0, "Folder not empty. Clean up first\n" );
        }
} else {
        Util::trace( 0, "Cannot find folder\n" );
}
};
if ($@) { &Error::catch_ex( $@ ); }
# Disconnect from the server
Util::disconnect();
# To mitigate SSL warnings by default
BEGIN {
	$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
}
