#!/usr/bin/perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
#use SDK::Hardware;
use SDK::Error;
use Try::Tiny;
use Scalar::Util qw( blessed );
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
try {
#	BaseException->throw( error => 'Hiba faszom' );
	NoEntityException->throw( error => 'Nincs faszom', entity => 'Halozat1-23' );
}
catch {
	print Dumper($_);
	die $_ unless blessed $_ && $_->can('rethrow');
	if ( $_->isa('BaseException') ) {
          warn $_->error, "\n";
		warn "Entity name:" .  $_->entity ."\n";
          exit;
      }
}
Util::disconnect();
# To mitigate SSL warnings by default
BEGIN {
	$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
}
