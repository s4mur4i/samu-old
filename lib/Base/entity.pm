package entity;

use strict;
use warnings;
use BB::Log;
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
        clone => { helper => 'VM_functions/VM_clone_function', function => \&clone_vm, },
        info => {
            helper => 'VM_functions/VM_info_function',
            functions => {
                dumper => { helper => 'AUTHOR', function => \&info_dumper },
                runtime => { helper => 'AUTHOR', function => \&info_runtime },
            }
        },
        add => {
            helper => 'VM_functions/VM_add_function',
            functions => {
                cdrom => { helper => 'AUTHOR', function => \&add_cdrom },
                network => { helper => 'AUTHOR', function => \&add_network },
                disk => { helper => 'AUTHOR', function => \&add_disk },
                snapshot => { helper => 'AUTHOR', function => \&add_snapshot },
            },
        },
        delete => {
            helper => 'VM_functions/VM_delete_function',
            functions => {
                cdrom => { helper => 'AUTHOR', function => \&delete_cdrom },
                network => { helper => 'AUTHOR', function => \&delete_network },
                disk => { helper => 'AUTHOR', function => \&delete_disk },
                snapshot => { helper => 'AUTHOR', function => \&delete_snapshot },
            },
        },
        list => {
            helper => 'VM_functions/VM_list_function',
            functions => {
                cdrom => { helper => 'AUTHOR', function => \&list_cdrom },
                network => { helper => 'AUTHOR', function => \&list_network },
                disk => { helper => 'AUTHOR', function => \&list_disk },
                snapshopt => { helper => 'AUTHOR', function => \&list_snapshot },
            },
        },
        change => {
            helper => 'VM_functions/VM_change_function',
            functions => {
                cdrom => { helper => 'AUTHOR', function => \&change_cdrom },
                network => { helper => 'AUTHOR', function => \&change_network },
                disk => { helper => 'AUTHOR', function => \&change_disk },
                snapshot => { helper => 'AUTHOR', function => \&change_snapshot },
                power => { helper => 'AUTHOR', function => \&change_power },
            },
        },
    },
};

sub main {
    &Log::debug("Entity::main sub started");
    &misc::option_parser($module_opts,"main");
}

sub list_cdrom {

}

sub list_network {

}

sub list_disk {

}

sub list_snapshot {

}

sub clone_vm {
    &Log::debug("Entity::clone sub started");
}
1;
__END__
