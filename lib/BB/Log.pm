package Log;
use strict;
use warnings;
#
# Last change:
#   by  $Author: gabsimon $
#   on  $Date: 2010-12-10 12:43:07 +0100 (Fri, 10 Dec 2010) $
#
use Getopt::Long qw(:config bundling pass_through);
use Sys::Syslog qw(:standard :macros);
use File::Basename;

my $verbosity;

sub verbosity() {
    return $verbosity;
}

# format a log message
# args: (generic description, followed by arguments as a hash)
# example: $l = log2line('Incoming connection', ip => '1.2.3.4', local_port => 1234, remote_port => $rport);
sub log2line {
    my $level = shift;
    my $msg = shift;
    my %args = @_;
    my $sep = '';
    my ($package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require) = caller(1);
    my $prefix = basename($filename) . " " . getpwuid($<) . " [$level] [".$$."]";

    closelog();
    openlog($prefix, "", LOG_USER);
    $msg .= ';';
    for my $k (sort keys %args) {
        my $v = $args{$k};

        defined($v) or $v = '(undef)';
        $v =~ s/\\/\\\\/g;
        $v =~ s/'/\\'/g;
        $v =~ s/\t/\\t/g;
        $v =~ s/\r/\\r/g;
        $v =~ s/\n/\\n/g;
        $v =~ s/\0/\\0/g;
        $msg .= "$sep $k='$v'";
        $sep = ',';
    }
    print STDERR "$prefix: $msg\n";
    return "$msg\n";
}

# Report a critical error and terminate the script
sub critical {
    syslog(LOG_ERR, log2line('ERROR', @_));
    die;
}

sub normal {
    syslog(LOG_INFO, log2line('INFO', @_));
}

# Report a warning but continue
sub warning {
    (verbosity() >= 1) and syslog(LOG_WARNING, log2line('WARNING', @_));
    return -1; # failure
}

# Send an info message
sub info {
    (verbosity() >= 2) and syslog(LOG_INFO, log2line('INFO', @_));
}

# Send a debug message
sub debug {
    (verbosity() >= 3) and syslog(LOG_DEBUG, log2line('DEBUG', @_));
}

BEGIN() {
    use Exporter();
    our (@ISA, @EXPORT);

    @ISA         = qw(Exporter);
    @EXPORT      = qw(&verbosity &critical &warning &info &debug &normal);

    GetOptions(
        "verbose|v+"    => \$verbosity, # occurence counter
    );
    $verbosity  ||= 0;

    debug("==== Log started");
    debug("Verbosity level verbosity=>'$verbosity'");
}

1;
# vim:ft=perl:ai:si:ts=4:sw=4:et
