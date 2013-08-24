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

sub main {
    &Log::debug("Entity::main sub started");
    switch ($ARGV[0]) {
        case "clone"   { shift @ARGV; &clone }
        case "add" { shift @ARGV; &add }
        case "delete" { shift @ARGV; &delete }
        case "list" { shift @ARGV; &list }
        case "change" { shift @ARGV; &change }
        else    { pod2usage(-verbose => 99, -noperldoc => 1, -output => \*STDOUT, -sections => [ qw(VM) ] ); }
    }
}

sub list {
    &Log::debug("Entity::list sub started");
    GetOptions(
        'help|h' => \$help,
    );
    &Log::debug("list help is=>'$help'");
    if ($help) {
        &Log::debug("List Help requested");
        pod2usage(-verbose => 99, -noperldoc => 1, -output => \*STDOUT, -sections => [ qw(VM_list_function) ] );
    }

}

sub clone {
    &Log::debug("Entity::clone sub started");
    GetOptions(
        'help|h' => \$help,
    );
    &Log::debug("Clone help is=>'$help'");
    if ($help) {
        &Log::debug("Clone Help requested");
        pod2usage(-verbose => 99, -noperldoc => 1, -output => \*STDOUT, -sections => [ qw(VM_clone_funtion) ] );
    }
}

sub add {
    &Log::debug("Entity::add sub started");
    GetOptions(
        'help|h' => \$help,
    );
    &Log::debug("Add help is=>'$help'");
    if ($help) {
        &Log::debug("Add Help requested");
        pod2usage(-verbose => 99, -noperldoc => 1, -output => \*STDOUT, -sections => [ qw(VM_add_function) ] );
    }
}

sub delete {
    &Log::debug("Entity::delete sub started");
    GetOptions(
        'help|h' => \$help,
    );
    &Log::debug("Delete help is=>'$help'");
    if ($help) {
        &Log::debug("Delete Help requested");
        pod2usage(-verbose => 99, -noperldoc => 1, -output => \*STDOUT, -sections => [ qw(VM_delete_function) ] );
    }
}

sub change {
    &Log::debug("Entity::change sub started");
    GetOptions(
        'help|h' => \$help,
    );
    &Log::debug("Change help is=>'$help'");
    if ($help) {
        &Log::debug("Change Help requested");
        pod2usage(-verbose => 99, -noperldoc => 1, -output => \*STDOUT, -sections => [ qw(ENTITY_CHANGE) ] );
    }
}

1;
__END__
