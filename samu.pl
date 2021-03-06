#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;
use FindBin;
use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/vmware_lib";
use BB::Log;
use Getopt::Long qw(:config bundling pass_through require_order);
use Pod::Usage;
use Base::misc;
use 5.14.0;
use BB::Common;

my $help = 0;
my $man  = 0;

# To mitigate SSL warnings by default
BEGIN {
    $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
}

my $samu_opts = {
    helper    => [qw(SYNOPSIS OPTIONS FUNCTIONS)],
    functions => {
        vm => {
            helper   => 'VM',
            module   => 'entity',
            function => \&entity::main
        },
        datastore => {
            helper   => 'DATASTORE',
            module   => 'datastore',
            function => \&datastore::main
        },
        kayako => {
            helper   => 'KAYAKO',
            module   => 'kayako',
            function => \&kayako::main
        },
        ticket => {
            helper   => 'TICKET',
            module   => 'ticket',
            function => \&ticket::main
        },
        bugzilla => {
            helper   => 'BUGZILLA',
            module   => 'bugzilla',
            function => \&bugzilla::main
        },
        admin => {
            helper   => 'ADMIN',
            module   => 'admin',
            function => \&admin::main
        },
        network => {
            helper   => 'NETWORK',
            module   => 'network',
            function => \&network::main
        },
        devel => {
            helper   => 'DEVEL',
            module   => 'devel',
            function => \&devel::main
        },
    }
};

sub podman {
    &Log::debug("Man requested");
    pod2usage(
        {
            -verbose => 2,
            -input   => $FindBin::Bin . "/doc/main.pod",
            -output  => \*STDOUT
        }
    );
}

sub podhelp {
    &Log::debug("Help requested");
    pod2usage(
        {
            -verbose   => 99,
            -output    => \*STDOUT,
            -input     => $FindBin::Bin . "/doc/main.pod",
            -noperldoc => 1,
            -sections  => [qw(SYNOPSIS OPTIONS FUNCTIONS)]
        }
    );
}

### Main
&Log::debug("Starting Samu");

GetOptions(
    'help|h' => \&podhelp,
    'man|m'  => \&podman,
);

eval { &misc::option_parser( $samu_opts, "samu_main" ); };
if ($@) {
    &Log::debug("There was an error need to run the catch_ex sub");
    &Error::catch_ex($@);
}
