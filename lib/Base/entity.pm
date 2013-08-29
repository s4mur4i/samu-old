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
        clone => {
            function => \&clone_vm,
            opts => {
                ticket => {
                    type => "=s",
                    help => "The ticket id the machine is going to be created for",
                    required => 1,
                },
                os_temp => {
                    type => "=s",
                    help => "The machine tempalte we want to use",
                    required => 1,
                },
                parent_pool => {
                    type => "=s",
                    help => "Parent resource pool. Defaults to users pool.",
                    default => 'Resources',
                    required => 0,
                },
                memory => {
                    type => "=s",
                    help => "Requested memory in MB",
                    required => 0,
                },
                cpu => {
                    type => "=s",
                    help => "Requested Core count for machine",
                    required => 0,
                },
                domain => {
                    type => "",
                    help => "Should the requested machine be added to support.ittest.domain",
                    required => 0,
                },
            },
        },
        info => {
            functions => {
                dumper => { helper => 'AUTHOR', function => \&info_dumper },
                runtime => { helper => 'AUTHOR', function => \&info_runtime },
            },
            opts => {},
        },
        add => {
            functions => {
                cdrom => { helper => 'AUTHOR', function => \&add_cdrom },
                network => { helper => 'AUTHOR', function => \&add_network },
                disk => { helper => 'AUTHOR', function => \&add_disk },
                snapshot => { helper => 'AUTHOR', function => \&add_snapshot },
            },
            opts => {},
        },
        delete => {
            functions => {
                cdrom => { helper => 'AUTHOR', function => \&delete_cdrom },
                network => { helper => 'AUTHOR', function => \&delete_network },
                disk => { helper => 'AUTHOR', function => \&delete_disk },
                snapshot => { helper => 'AUTHOR', function => \&delete_snapshot },
            },
            opts => {},
        },
        list => {
            functions => {
                cdrom => { helper => 'AUTHOR', function => \&list_cdrom },
                network => { helper => 'AUTHOR', function => \&list_network },
                disk => { helper => 'AUTHOR', function => \&list_disk },
                snapshopt => { helper => 'AUTHOR', function => \&list_snapshot },
            },
            opts => {},
        },
        change => {
            functions => {
                cdrom => { helper => 'AUTHOR', function => \&change_cdrom },
                network => { helper => 'AUTHOR', function => \&change_network },
                disk => { helper => 'AUTHOR', function => \&change_disk },
                snapshot => { helper => 'AUTHOR', function => \&change_snapshot },
                power => { helper => 'AUTHOR', function => \&change_power },
            },
            opts => {},
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
