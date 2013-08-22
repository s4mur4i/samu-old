#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;
use FindBin;
use lib "$FindBin::Bin/lib";
use Getopt::Long qw(:config bundling pass_through require_order);
use SDK::Log;
use VMware::VIRuntime;
use Pod::Usage;
use entity;
use Switch;

my $help = 0;
my $man = 0;

### Subs

### Pod Begin ###
=pod

=head1 VM_NAME

    Entity sub module options

=head1 VM_OPTIONS

=over

=item B<-help|h>
    Print the help page to STDERR

=back

=cut
### Pod End ###

sub entity {
    &Log::debug("Entity has been called");
    GetOptions(
        'help|h' => \$help,
    );
    &Log::debug("Entity help is=>'$help'");
    if ($help) {
        &Log::debug("Entity Help requested");
        pod2usage(-verbose => 99, -noperldoc => 1, -sections => [ qw(VM_NAME VM_OPTIONS AUTHOR) ] );
    }

}

sub podman {
    #pod2usage({-verbose => 99, -sections => [ qw(NAME SYNOPSIS OPTIONS DESCRIPTIONS FILES BUGS AUTHOR) ]});
    pod2usage({-verbose => 2});
}
### Main
&Log::debug("Starting Script");
GetOptions(
    'help|h' => \$help,
    'man|m' => \$man,
    );

if ($help) {
    &Log::debug("Help requested");
    pod2usage({-verbose => 99, -noperldoc => 1, -sections => [ qw(NAME SYNOPSIS OPTIONS DESCRIPTIONS FILES BUGS AUTHOR) ] });
}
if ($man or !defined($ARGV[0])) {
    &Log::debug("Man requested");
    &podman;
}

switch ($ARGV[0]) {
    case "vm"     { shift; &entity }
    else          { &podman }
}
__END__

=head1 NAME

    jew.pl -- Support automatisation script

=head1 SYNOPSIS

    jew.pl [-v] [options]

=head1 OPTIONS

=over

=item B<--help|-h>

    Print the help page to STDERR

=item B<--man|-m>

    Print the man page

=item B<-v|-vv|-vvv>

    Increase verbosity of printing

=item B<vm>

    Access VM Entity functions

=item B<datastore>

    Access Datastore functions

=back

=head1 DESCRIPTION

    Wrapper script for all functions

    To get information about any sub module call any option with help

=head1 BUGS

    Known Bugs:

=over

=item * We are still experimental...could be alot of problems

=back

=head1 FILES

    SDK uses the default ~/.visdkrc for storing enviromental values.
    Further information can be found on: https://supportwiki.balabit/doku.php/products:vmware:infra_info

=head1 AUTHOR

    Krisztian Banhidy < s4mur4i@balabit.hu >

=cut
