package entity;

use strict;
use warnings;
use Data::Dumper;
use BB::Log;
use Switch;
use Getopt::Long qw(:config bundling pass_through require_order);
use VMware::VIRuntime;
use Pod::Usage;
use Base::misc;

my $help = 0;
BEGIN() {
    use Exporter();
    our (@ISA, @EXPORT);

    @ISA         = qw(Exporter);
    @EXPORT      = qw(&main);
}

### subs

=pod

=head1 ENTITY_MAIN

=head2 DESCRIPTION

    This is the main entry sub to the vm (entity) functions. All further functions can be reached from here

=cut

our $module_opts = {
    helper => 'VM',
    functions => {
        clone => {function => \&clone, },
        add => {function => \&add, },
        delete => {function => \&delete, },
        list => {
            helper => 'VM_list_function',
            functions => {
                cdrom => { helper => 'AUTHOR', function => \&list_cdrom },
                network => { helper => 'AUTHOR', function => \&list_network},
                disk => { helper => 'AUTHOR', function => \&list_disk},
                snapshopt => {helper => 'AUTHOR', function => \&list_snapshot},
            },
        },
        change => {function => \&change, },
    }
};

sub main {
    &Log::debug("Entity::main sub started");
    &misc::option_parser($module_opts,"main");
}

1;
__END__
