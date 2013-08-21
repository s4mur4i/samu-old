#!/usr/bin/perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
#use SDK::Hardware;
use SDK::Error;
use SDK::Vcenter;
use VMware::VIRuntime;
use Data::Dumper;
my %opts = (
);
Opts::add_options(%opts);
Opts::parse();
Opts::validate();
my $username = Opts::get_option('username');
my $password = Opts::get_option('password');
my $url = Opts::get_option('url');
Util::connect( $url, $username, $password );
# Disconnect from the server
eval {
	&Vcenter::vm_num_check('a');
};
if ($@) {
	&Error::catch_ex( $@ );
}
Util::disconnect();
# To mitigate SSL warnings by default
BEGIN {
	$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
}
