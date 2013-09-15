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

my $verbose;
my $quiet;
my $verbosity;

#tested
sub verbosity {
    return $verbosity;
}

# format a log message
# args: (generic description, followed by arguments as a hash)
# example: $l = log2line('Incoming connection', ip => '1.2.3.4', local_port => 1234, remote_port => $rport);
sub log2line {
    my $level = shift;
    my $msg   = shift;
    my %args  = @_;
    my $sep   = '';
    my ( $package, $filename,  $line,     $subroutine, $hasargs, $wantarray, $evaltext, $is_require) = caller(1);
    my $prefix = basename($filename) . " " . getpwuid($<) . " [$level] [" . $$ . "]";
    my $prefix_stderr = basename($filename) . " " . [$level];
    closelog();
    openlog( $prefix, "", LOG_USER );
    $msg .= ';';
    for my $k ( sort keys %args ) {
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
    print STDERR "$prefix_stderr: $msg\n";
    return "$msg\n";
}

sub debug2 {
    ( verbosity() >= 10 ) and syslog( LOG_DEBUG, log2line( 'DEBUG2', @_ ) );
}

sub debug1 {
    ( verbosity() >= 9 ) and syslog( LOG_DEBUG, log2line( 'DEBUG1', @_ ) );
}

sub debug {
    ( verbosity() >= 8 ) and syslog( LOG_DEBUG, log2line( 'DEBUG', @_ ) );
}

sub info {
    ( verbosity() >= 7 ) and syslog( LOG_INFO, log2line( 'INFO', @_ ) );
}

sub notice {
    ( verbosity() >= 6 ) and syslog( LOG_NOTICE, log2line( 'NOTICE', @_ ) );
}

sub warning {
    ( verbosity() >= 5 ) and syslog( LOG_WARNING, log2line( 'WARNING', @_ ) );
}

sub error {
    ( verbosity() >= 4 ) and syslog( LOG_ERR, log2line( 'ERROR', @_ ) );
}

sub critical {
    ( verbosity() >= 3 ) and syslog( LOG_CRIT, log2line( 'CRITICAL', @_ ) );
}

sub alert {
    ( verbosity() >= 2 ) and syslog( LOG_ALERT, log2line( 'ALERT', @_ ) );
}

sub emergency {
    ( verbosity() >= 1 ) and syslog( LOG_EMERG, log2line( 'EMERGENCY', @_ ) );
}

BEGIN {
    use Exporter();
    our ( @ISA, @EXPORT );

    @ISA    = qw(Exporter);
    @EXPORT = qw( );

    GetOptions(
        "v+" => \$verbose,    # occurence counter
        "q+" => \$quiet,    # occurence counter
    );
    $quiet ||=0;
    $verbose ||= 0;
    $verbosity = ( 6 + $verbose ) - $quiet;
    if ( $verbosity < 0 ) {
        $verbosity = 0;
    } elsif ( $verbosity > 10 ) {
        $verbosity =10;
    }

    debug("==== Log started");
    debug("Verbosity level verbosity=>'$verbosity'");
}

1;
