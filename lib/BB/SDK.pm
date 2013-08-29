package SDK;

use strict;
use warnings;
use VMware::VIRuntime;

BEGIN {
    use Exporter;
    our @ISA = qw( Exporter );
    our @EXPORT = qw( &single_entity_name &multiple_entity_name );
}

sub single_entity_name {
    my ( $name, $type ) = @_;
    my $view = Vim::find_entity_view( view_type => $type, properties => [ 'name' ], filter => { name => $name } );
    return $view;
}

sub multiple_entity_name {
    my ( $name, $type ) = @_;
    my $view = Vim::find_entity_views( view_type => $type, properties => [ 'name' ], filter => { name => $name } );
    return $view;
}

1
__END__
