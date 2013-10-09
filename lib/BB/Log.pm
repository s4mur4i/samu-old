package Log;

use strict;
use warnings;

use Getopt::Long qw(:config bundling pass_through);
use Sys::Syslog qw(:standard :macros);
use File::Basename;
use Data::Dumper;

my $verbose;
my $quiet;
my $verbosity;

=pod

=head1 verbostiy

=head2 PURPOSE

Returns verbosity level

=head2 PARAMETERS

=over

=back

=head2 RETURNS

Returns verbosity level

=head2 DESCRIPTION

Getter sub for verbosity

=head2 THROWS

=head2 COMMENTS

=head2 SEE ALSO

=cut

sub verbosity {
    return $verbosity;
}

=pod

=head1 log2line

=head2 PURPOSE

Formats a log message

=head2 PARAMETERS

=over

=item level

Level of information

=item msg

The requested log information

=back

=head2 RETURNS

The formatted log message

=head2 DESCRIPTION

=head2 THROWS

=head2 COMMENTS

=head2 SEE ALSO

=cut

sub log2line {
    $0 =~ s/.*\///g;    # strip off the leading . from the program name
    my $level = shift;
    my $msg   = shift;
    my %args  = @_;
    my $sep   = '';
    my (
        $package, $filename,  $line,     $subroutine,
        $hasargs, $wantarray, $evaltext, $is_require
    ) = caller(1);
    my $prefix =
        $0 . "["
      . $$ . "]: ("
      . basename($filename) . ") "
      . getpwuid($<)
      . " [$level]";
    my $prefix_stderr = basename($filename) . " [$level]";
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

=pod

=head1 debug2

=head2 PURPOSE

debug 2 for printing information at log level 10

=head2 PARAMETERS

=over

=item msg

Message to print

=back

=head2 RETURNS

=head2 DESCRIPTION

=head2 THROWS

=head2 COMMENTS

=head2 SEE ALSO

=cut

sub debug2 {
    ( verbosity() >= 10 ) and syslog( LOG_DEBUG, log2line( 'DEBUG2', @_ ) );
}

=pod

=head1 debug1

=head2 PURPOSE

debug 1 for printing information at log level 9

=head2 PARAMETERS

=over

=item msg

Message to print

=back

=head2 RETURNS

=head2 DESCRIPTION

=head2 THROWS

=head2 COMMENTS

=head2 SEE ALSO

=cut

sub debug1 {
    ( verbosity() >= 9 ) and syslog( LOG_DEBUG, log2line( 'DEBUG1', @_ ) );
}

=pod

=head1 debug

=head2 PURPOSE

debug for printing information at log level 8

=head2 PARAMETERS

=over

=item msg

Message to print

=back

=head2 RETURNS

=head2 DESCRIPTION

=head2 THROWS

=head2 COMMENTS

=head2 SEE ALSO

=cut

sub debug {
    ( verbosity() >= 8 ) and syslog( LOG_DEBUG, log2line( 'DEBUG', @_ ) );
}

=pod

=head1 info

=head2 PURPOSE

info for printing information at log level 7

=head2 PARAMETERS

=over

=item msg

Message to print

=back

=head2 RETURNS

=head2 DESCRIPTION

=head2 THROWS

=head2 COMMENTS

=head2 SEE ALSO

=cut

sub info {
    ( verbosity() >= 7 ) and syslog( LOG_INFO, log2line( 'INFO', @_ ) );
}

=pod

=head1 notice

=head2 PURPOSE

notice for printing information at log level 6

=head2 PARAMETERS

=over

=item msg

Message to print

=back

=head2 RETURNS

=head2 DESCRIPTION

=head2 THROWS

=head2 COMMENTS

=head2 SEE ALSO

=cut

sub notice {
    ( verbosity() >= 6 ) and syslog( LOG_NOTICE, log2line( 'NOTICE', @_ ) );
}

=pod

=head1 warning

=head2 PURPOSE

warning for printing information at log level 5

=head2 PARAMETERS

=over

=item msg

Message to print

=back

=head2 RETURNS

=head2 DESCRIPTION

=head2 THROWS

=head2 COMMENTS

=head2 SEE ALSO

=cut

sub warning {
    ( verbosity() >= 5 ) and syslog( LOG_WARNING, log2line( 'WARNING', @_ ) );
}

=pod

=head1 error

=head2 PURPOSE

error for printing information at log level 4

=head2 PARAMETERS

=over

=item msg

Message to print

=back

=head2 RETURNS

=head2 DESCRIPTION

=head2 THROWS

=head2 COMMENTS

=head2 SEE ALSO

=cut

sub error {
    ( verbosity() >= 4 ) and syslog( LOG_ERR, log2line( 'ERROR', @_ ) );
}

=pod

=head1 ciritical

=head2 PURPOSE

Critical for printing information at log level 3

=head2 PARAMETERS

=over

=item msg

Message to print

=back

=head2 RETURNS

=head2 DESCRIPTION

=head2 THROWS

=head2 COMMENTS

=head2 SEE ALSO

=cut

sub critical {
    ( verbosity() >= 3 ) and syslog( LOG_CRIT, log2line( 'CRITICAL', @_ ) );
}

=pod

=head1 alert

=head2 PURPOSE

alert for printing information at log level 2

=head2 PARAMETERS

=over

=item msg

Message to print

=back

=head2 RETURNS

=head2 DESCRIPTION

=head2 THROWS

=head2 COMMENTS

=head2 SEE ALSO

=cut

sub alert {
    ( verbosity() >= 2 ) and syslog( LOG_ALERT, log2line( 'ALERT', @_ ) );
}

=pod

=head1 emergency

=head2 PURPOSE

emergency for printing information at log level 1

=head2 PARAMETERS

=over

=item msg

Message to print

=back

=head2 RETURNS

=head2 DESCRIPTION

=head2 THROWS

=head2 COMMENTS

=head2 SEE ALSO

=cut

sub emergency {
    ( verbosity() >= 1 ) and syslog( LOG_EMERG, log2line( 'EMERGENCY', @_ ) );
}

=pod

=head1 dumpobj

=head2 PURPOSE

Dumps an object for debugging

=head2 PARAMETERS

=over

=item name

Name of object for better identification

=item obj

Object to dump

=back

=head2 RETURNS

=head2 DESCRIPTION

=head2 THROWS

=head2 COMMENTS

=head2 SEE ALSO

=cut

sub dumpobj {
    my ( $name, $obj ) = @_;
    ( verbosity() >= 10 ) and debug2( "Dumping object $name:" . Dumper($obj) );
}

=pod

=head1 loghash

=head2 PURPOSE

Logs a hash to readable format

=head2 PARAMETERS

=over

=item msg

Message to log to hash

=item hash

Hashref to log

=back

=head2 RETURNS

=head2 DESCRIPTION

=head2 THROWS

=head2 COMMENTS

=head2 SEE ALSO

=cut

sub loghash {
    my ( $msg, $hash ) = @_;
    ( verbosity() >= 8 ) and debug(
        $msg
          . (
            join ',', ( map { "$_=>'" . $hash->{$_} . "'" } sort keys %{$hash} )
          )
    );
}

BEGIN {
    use Exporter();
    our ( @ISA, @EXPORT );

    @ISA    = qw(Exporter);
    @EXPORT = qw( );

    GetOptions(
        "v+" => \$verbose,    # occurence counter
        "q+" => \$quiet,      # occurence counter
    );
    $quiet   ||= 0;
    $verbose ||= 0;
    $verbosity = ( 6 + $verbose ) - $quiet;
    if ( $verbosity < 0 ) {
        $verbosity = 0;
    }
    elsif ( $verbosity > 10 ) {
        $verbosity = 10;
    }

    debug("==== Log started");
    debug("Verbosity level verbosity=>'$verbosity'");
}

1;
