package Misc;

use strict;
use warnings;
use BB::Error;

BEGIN {
    use Exporter;
    our @ISA = qw( Exporter );
    our @EXPORT = qw( &array_longest);
}

sub array_longest {
    my ( $array ) = @_;
    my $max = -1;
    for ( @$array ) {
        if ( length > $max ) {
            $max = length;
        }
    }
    return $max;
}


1
__END__
