package entity;

use strict;
use warnings;

BEGIN() {
    use Exporter();
    our (@ISA, @EXPORT);

    @ISA         = qw(Exporter);
    @EXPORT      = qw(&main);

    &Log::debug("==== Entity modul started");
}

my $help = 0;

sub main {
    print 0;
}

1;
__END__

=head1 NAME

    entity submodul

=cut
