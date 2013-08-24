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
                help => "Inventory folder to list. If not give all inventory folders will be listed.",
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
Util::connect( $url, $username, $password );
eval {
if (defined($name)) {
        &Vcenter::print_folder_content($name);
} else {
	## FIXME Remove the hidden folder structure, or rethink this hiearchy.
        my $folder_view = Vim::find_entity_views(view_type => 'Folder');
        foreach (@$folder_view) {
                &Vcenter::print_folder_content($_->name);
        }
}
};
if ($@) { &Error::catch_ex( $@ ); }
# Disconnect from the server
Util::disconnect();
# To mitigate SSL warnings by default
BEGIN {
	$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
}
