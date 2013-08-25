#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;
use FindBin;
use lib "$FindBin::Bin/lib";
use BB::Log;
use Getopt::Long qw(:config bundling pass_through require_order);
use VMware::VIRuntime;
use Pod::Usage;
use Base::misc;
use Switch;
use 5.14.0;

my $help = 0;
my $man = 0;

my $jew_opts = {
    helper => [ qw(SYNOPSIS OPTIONS FUNCTIONS) ],
    functions => {
        vm => { helper => 'VM', module => 'entity', function => \&entity::main },
        datastore => { helper => 'DATASTORE', module => 'datastore', function => \&datastore::main },
        kayako => { helper => 'KAYAKO', module => 'kayako', function => \&kayako::main },
        ticket => { helper => 'TICKET', module => 'ticket', function => \&ticket::main },
        bugzilla => { helper => 'BUGZILLA', module => 'bugzilla', function => \&bugzilla::main },
        admin => { helper => 'ADMIN', module => 'admin', function => \&admin::main },
    }
};

sub podman {
    &Log::debug("Man requested");
    pod2usage({-verbose => 2, -input => $FindBin::Bin . "/doc/main.pod",-output => \*STDOUT});
}

sub podhelp {
    &Log::debug("Help requested");
    pod2usage({-verbose => 99, -output => \*STDOUT ,-input => $FindBin::Bin . "/doc/main.pod", -noperldoc => 1, -sections => [ qw(SYNOPSIS OPTIONS FUNCTIONS) ] });
}

### Main
&Log::debug("Starting Script");

GetOptions(
    'help|h' => \&podhelp,
    'man|m' => \&podman,
    );

&misc::option_parser($jew_opts,"jew_main");

__END__
