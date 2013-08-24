package entity;

use strict;
use warnings;
use Data::Dumper;
use BB::Log;
use Switch;
use Getopt::Long qw(:config bundling pass_through require_order);
use VMware::VIRuntime;
use Pod::Usage;

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
    &option_parser($module_opts,"main");
}

sub option_parser($$) {
    my $opts = shift;
    my $module_name = shift;
    GetOptions(
            'help|h' => \$help,
            );
    $help and pod2usage(-verbose => 99, -noperldoc => 1, -output => \*STDOUT, -sections => [ $opts->{helper} ] );
    if (exists $opts->{function}) {
        &Log::debug("Invoking handler function of $module_name");
        &{$opts->{function}};
    }

    my $arg = shift @ARGV;
    if (defined $arg and exists $opts->{functions}->{$arg}) {
           &Log::debug("Forwarding parsing to subfunction parser $arg");
           &option_parser($opts->{functions}->{$arg},$arg);
    } else {
        pod2usage(-verbose => 99, -noperldoc => 1, -output => \*STDOUT, -sections => [ $opts->{helper} ] );
    }
}

1;
__END__
