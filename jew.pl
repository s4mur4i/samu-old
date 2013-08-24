#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;
use FindBin;
use lib "$FindBin::Bin/lib";
#use BB::Log qw(debug error normal info);
use BB::Log;
use Getopt::Long qw(:config bundling pass_through require_order);
use VMware::VIRuntime;
use Pod::Usage;
use Base::misc;
use Switch;

my $help = 0;
my $man = 0;

my $jew_opts = {
    helper => [ qw(SYNOPSIS OPTIONS) ],
    functions => {
        vm => { helper => 'VM', module => 'entity', function => \&entity::main },
        datastore => { helper => 'AUTHOR', module => 'datastore', function => \&datastore::main },
    }
};

=pod

=head1 NAME

    jew.pl -- Support automatisation script

=head1 DESCRIPTION

    This script is used as a wrapper script for automatisation task used by support.

    To get information about any sub module call any option with help

=head1 SYNOPSIS

    jew.pl [-v] [--help|-h] [--man|-m] [options]

=head1 OPTIONS

=over

=item I<--help|-h>

    Print the help page

=item I<--man|-m>

    Print the man page

=item I<-v|-vv|-vvv>

    Increase verbosity of printing

=item I<vm>

    Access VM Entity functions

=item I<datastore>

    Access Datastore functions

=item I<ticket>

    Access ticket functions

=back

=head1 SUBS

    List of defined function, each can be called with it's own help and detailed information. Each sub has their own help defined.

=head1 VM

=head2 SYNOPSIS

    jew.pl vm [options]

=head2 OPTIONS

=over

=item I<-help|h>

    Print the help page

=item I<clone>

    Sub used to provision vm guests from templates.

=item I<add>

    Sub to add different hardwares to a guest

=item I<list>

    Sub to list different hardwares of a guest

=item I<delete>

    Sub to delete/remove different hardwares of a guest

=item I<change>

    Sub to change hardware settings of a guest

=back

=head1 VM_list_function

=head2 SYNOPSIS

    jew.pl vm list [options]

=head2 OPTIONS

=over

=item I<network>

    List network interfaces attached to a vm

=item I<cdrom>

    List cdrom-s attached to a vm

=item I<disk>

    List disk-s attached to a vm

=item I<snapshot>

    List snapshots attached to a vm

=back

=head1 VM_add_function

=head2 SYNOPSIS

    jew.pl vm add [options]

=head2 OPTIONS

=over

=item I<cdrom>

    Add a cdrom drive to a vm

=item I<network>

    Add a network interface to a vm

=item I<disk>

    Add a thin provisioned hard disk to a vm

=item I<snapshot>

    List snapshots attached to a vm

=back

=head1 VM_delete_function

=head2 SYNOPSIS

    jew.pl vm delete [options]

=head2 OPTIONS

=over

=item I<cdrom>

    Delete a cdrom drive to a vm

=item I<network>

    Delete a network interface to a vm

=item I<disk>

    Delete a hard disk from a vm

=item I<snapshot>

    List snapshots attached to a vm

=back

=head1 VM_change_function

=head2 SYNOPSIS

    jew.pl vm change [options]

=head2 OPTIONS

=over

=item I<cdrom>

    Change the backend iso to a cdrom drive

=item I<network>

    Change the network connected to a network

=item I<altername>

    Change the alternative name of a vm

=item I<snapshot>

    List snapshots attached to a vm

=back

=head1 TICKET

=head2 SYNOPSIS

    jew.pl ticket [options]

=head2 OPTIONS

=over

=item I<-help|h>

    Print the help page

=back

=head1 DATASTORE

=head2 SYNOPSIS

    jew.pl datastore [options]

=head2 OPTIONS

=over

=item I<-help|h>

    Print the help page

=back

=head1 KAYAKO

=head2 SYNOPSIS

    jew.pl kayako [options]

=head2 OPTIONS

=over

=item I<-help|-h>

    Print the help page

=back

=cut

sub podman {
    &Log::debug("Man requested");
    pod2usage({-verbose => 2, -output => \*STDOUT});
}

sub podhelp {
    &Log::debug("Help requested");
    pod2usage({-verbose => 99, -output => \*STDOUT ,-noperldoc => 1, -sections => [ qw(SYNOPSIS OPTIONS) ] });
}

### Main
&Log::debug("Starting Script");

GetOptions(
    'help|h' => \&podhelp,
    'man|m' => \&podman,
    );

&misc::option_parser($jew_opts,"jew_main");

__END__

=head1 BUGS

    Known Bugs:

=over

=item * We are still experimental...could be alot of problems

=back

=head1 FILES

    SDK uses the default ~/.visdkrc for storing enviromental values.
    Further information can be found on: https://supportwiki.balabit/doku.php/products:vmware:infra_info

=head1 AUTHOR

    Krisztian Banhidy <s4mur4i@balabit.hu>

=cut
