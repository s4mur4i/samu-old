package misc;

use strict;
use warnings;
use Getopt::Long qw(:config bundling pass_through require_order);
use Pod::Usage;
use FindBin;

BEGIN {
    use Exporter();
    our ( @ISA, @EXPORT );

    @ISA    = qw(Exporter);
    @EXPORT = qw(&option_parser);
}

our $help;

sub call_pod2usage {
    my $helper = shift;
    pod2usage(
        -verbose   => 99,
        -noperldoc => 1,
        -input     => $FindBin::Bin . "/doc/main.pod",
        -output    => \*STDOUT,
        -sections  => $helper
    );
}

sub option_parser {
    &Log::debug("Misc::option_parser sub starting");
    my $opts        = shift;
    my $module_name = shift;
    if ( exists( $opts->{helper} ) ) {
        GetOptions( 'help|h' => \$help, );
        $help && &call_pod2usage( $opts->{helper} );
    }
    if ( exists $opts->{module} ) {
        my $module = 'Base::' . $opts->{module};
        &Log::debug("loading module $module");
        eval "use $module";
        $module->import();
    }
    if ( exists $opts->{function} ) {
        if ( exists $opts->{opts} ) {
            &Log::debug("Parsing options to VMware SDK");
            &VCenter::SDK_options( $opts->{opts} );
            eval {
                &Log::debug("Connecting to Vcenter");
                &VCenter::connect_vcenter();
            };
            if ($@) { &Error::catch_ex($@) }
        }
        &Log::debug("Invoking handler function of $module_name");
        &{ $opts->{function} };
        &Log::debug("Disconnecting from Vcenter");
        &VCenter::disconnect_vcenter();
    }
    else {
        my $arg = shift @ARGV;
        if ( defined $arg and exists $opts->{functions}->{$arg} ) {
            &Log::debug("Forwarding parsing to subfunction parser $arg");
            &option_parser( $opts->{functions}->{$arg}, $arg );
        }
        else {
            &Log::debug("Calling helper");
            call_pod2usage( $opts->{helper} );
        }
    }
}

sub test {
    return 0;
}
1
