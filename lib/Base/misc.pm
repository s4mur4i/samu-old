package misc;

use strict;
use warnings;
use BB::Log;
use Getopt::Long qw(:config bundling pass_through require_order);
use Pod::Usage;

BEGIN() {
    use Exporter();
    our (@ISA, @EXPORT);

    @ISA         = qw(Exporter);
    @EXPORT      = qw(&option_parser);
}

our $help;

sub option_parser($$) {
    my $opts = shift;
    my $module_name = shift;
    GetOptions(
            'help|h' => \$help,
            );
    $help and pod2usage(-verbose => 99, -noperldoc => 1, -output => \*STDOUT, -sections => $opts->{helper} );
    if (exists $opts->{module}) {
        my $module = 'Base::'.$opts->{module};
        &Log::debug("loading module $module");
        eval "use $module;";
        $module->import();
        #use "Base::$opt->{module}";
    }
    if (exists $opts->{function}) {
        &Log::debug("Invoking handler function of $module_name");
        &{$opts->{function}};
    }

    my $arg = shift @ARGV;
    if (defined $arg and exists $opts->{functions}->{$arg}) {
           &Log::debug("Forwarding parsing to subfunction parser $arg");
           &option_parser($opts->{functions}->{$arg},$arg);
    } else {
        pod2usage(-verbose => 99, -noperldoc => 1, -output => \*STDOUT, -sections => $opts->{helper} );
    }
}

1
