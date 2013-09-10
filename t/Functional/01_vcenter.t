#!/usr/bin/perl
use strict;
use warnings;
use 5.14.0;
use Test::More;
use Test::Files;
use Test::Trap;
use File::Spec::Functions qw(catfile);
use File::HomeDir qw(home);
use FindBin;
use lib "$FindBin::Bin/../../lib2/";
use VMware::VIRuntime;

BEGIN {
    ## Namespace mange is done here since only regex changes in each sub
    my %m = (
    username => qr /^\s*(VI_USERNAME)=[^=]*$/,
    password => qr /^\s*(VI_PASSWORD)=[^=]*$/,
    server => qr /^\s*(VI_SERVER)=[^=]*$/,
    port => qr /^\s*(VI_PORTNUMBER)=[^=]*$/,
    url => qr /^\s*(VI_URL)=[^=]*$/,
    protocol => qr /^\s*(VI_PROTOCOL)=[^=]*$/,
    service => qr /^\s*(VI_SERVICEPATH)=[^=]*$/,
    );

    for my $i (keys %m)
    {
        ## No strict refs is used since mangeling is done
        no strict 'refs';
        *{"filter_$i"} = sub {
            my $line = shift;
            if ($line =~ $m{$i}) {
                $line=$1;
            } else {
                $line = "";
            }
            return $line;
        }
    }
}

my $visdkrc = File::Spec->catfile( home(), '.visdkrc' );
file_filter_ok( $visdkrc, "VI_USERNAME", \&filter_username, "visdkrc contains username");
file_filter_ok( $visdkrc, "VI_PASSWORD", \&filter_password, "visdkrc contains password");
file_filter_ok( $visdkrc, "VI_SERVER", \&filter_server, "visdkrc contains server");
file_filter_ok( $visdkrc, "VI_PORTNUMBER", \&filter_port, "visdkrc contains port number");
file_filter_ok( $visdkrc, "VI_URL", \&filter_url, "visdkrc contains url");
file_filter_ok( $visdkrc, "VI_PROTOCOL", \&filter_protocol, "visdkrc contains protocol");
file_filter_ok( $visdkrc, "VI_SERVICEPATH", \&filter_service, "visdkrc contains servicepath");
is( &Opts::parse(), undef, "Parsing options" );
is( &Opts::validate(), undef, "Validating options");
ok( &Util::connect(), "Connecting to Vcenter");
is( &Util::disconnect(), undef, "Disconnecting from Vcenter");
diag("fail username");
&Opts::set_option("username", "test");
is( &Opts::parse(), undef, "Parsing incorrent username options" );
my @trap = trap { &Util::connect()};
is( $trap->exit, undef, "Fail to connect to Vcenter with incorrect username");
diag("fail password");
&Opts::set_option("username", "");
&Opts::set_option("password", "herring");
is( &Opts::parse(), undef, "Parsing incorrent password options" );
@trap = trap { &Util::connect()};
is( $trap->exit, undef, "Fail to connect to Vcenter with incorrect password");
diag("fail url");
&Opts::set_option("username", "");
&Opts::set_option("password", "");
&Opts::set_option("url", "https://herring/sdk");
is( &Opts::parse(), undef, "Parsing incorrent password options" );
@trap = trap { &Util::connect()};
is( $trap->exit, undef, "Fail to connect to Vcenter with incorrect url");
done_testing;
