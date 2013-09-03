#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;
use FindBin;
use lib "$FindBin::Bin/lib";
use BB::Log;
use Getopt::Long qw(:config bundling pass_through require_order);

#use VMware::VIRuntime;
use Pod::Usage;
use Base::misc;
use Switch;
use 5.14.0;
use BB::Common;

my $help = 0;
my $man  = 0;

# To mitigate SSL warnings by default
BEGIN {
    $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
}

my $herring_opts = {
    helper    => [qw(SYNOPSIS OPTIONS FUNCTIONS)],
    functions => {
        vm =>
          { helper => 'VM', module => 'entity', function => \&entity::main },
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
        admin =>
          { helper => 'ADMIN', module => 'admin', function => \&admin::main },
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
&Log::debug("Starting Script");

GetOptions(
    'help|h' => \&podhelp,
    'man|m'  => \&podman,
);

eval { &misc::option_parser( $herring_opts, "jew_main" ); };
if ($@) {
    &Error::catch_ex($@);
}
__END__