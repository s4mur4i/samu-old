package VCenter;

use strict;
use warnings;
use BB::Error;
use BB::Log;
use VMware::VIRuntime;
use Data::Dumper;

BEGIN {
    use Exporter;
    our @ISA = qw( Exporter );
    our @EXPORT = qw( &num_check &SDK_options &connet_vcenter &disconnect_vcenter );
}

sub num_check($$) {
    my ( $name, $type ) = @_;
    &Log::debug("Starting VCenter::num_check sub, name=>'$name', type=>'$type'");
    my $views = Vim::find_entity_views( view_type => $type, properties => [ 'name' ], filter => { name => $name } );
    if ( scalar(@$views) ne 1 ) {
        Entity::NumException->throw( error => 'Entity count not expected', entity => $name, count => scalar(@$views) );
    } else {
        &Log::debug("Entity is single");
        return 0;
    }
}

sub SDK_options(%) {
    my ( %opts ) = @_;
    &Log::debug("Starting VCenter::SDK_options");
    Opts::add_options(%opts);
    Opts::parse();
#    Opts::validate();
}

sub connect_vcenter {
    &Log::debug("Starting VCenter::connect_vcenter sub");
    eval {
    Util::connect( Opts::get_option('url'), Opts::get_option('username'), Opts::get_option('password') );
    };
    if ( $@ ) {
        Connection::Connect->throw( error => 'Failed to connect to VCenter', type => 'SDK', dest => 'VCenter' );
    }
}

sub disconnect_vcenter {
    &Log::debug("Starting VCenter::disconnect_vcenter sub");
    Util::disconnect();
}

1
__END__
