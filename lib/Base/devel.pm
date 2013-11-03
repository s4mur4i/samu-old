package devel;

use strict;
use warnings;
use Base::misc;
use FindBin;

=pod

=head1 devel.pm

Subroutines from Base/devel.pm

=cut

BEGIN() {
    use Exporter();
    our ( @ISA, @EXPORT );

    @ISA    = qw(Exporter);
    @EXPORT = qw();
}

our $module_opts = {
    helper    => 'DEVEL',
    functions => {
        create => {
            helper    => "DEVEL_functions/DEVEL_create_function",
            functions => {
                mainpod => {
                    function        => \&create_mainpod,
                    vcenter_connect => 0,
                    opts            => {
                        folder => {
                            type     => "=s",
                            help     => "Folder to take pod files from",
                            required => 0,
                            default  => "$FindBin::Bin/doc",
                        },
                        output => {
                            type     => "=s",
                            help     => "Output file",
                            required => 0,
                            default  => "main.pod",
                        },
                    },
                },
            },
        },
    },
};

=pod

=head1 module_opts

=head2 PURPOSE

Return Module_opts hash for testing

=head2 PARAMETERS

=over

=back

=head2 RETURNS

Hash ref containing module_opts

=head2 DESCRIPTION

=head2 THROWS

=head2 COMMENTS

=head2 TEST COVERAGE

=cut

sub module_opts {
    return $module_opts;
}

sub main {
    &Log::debug("Starting Devel::main sub");
    &misc::option_parser( $module_opts, "main" );
    &Log::debug("Finishing Devel::main sub");
    return 1;
}

sub create_mainpod {
    &Log::debug("Starting Devel::create_mainpod sub");
    my $folder = &Opts::get_option('folder');
    my $output = &Opts::get_option('output');
    &Log::debug1("Opts are: folder=>'$folder', output=>'$output'");
    my $outfile = "$folder/$output";
    if ( -f $outfile ) {
        &Log::debug("Unlinking outfile");
        unlink $outfile;
    }
    else {
        &Log::debug("No need to unlink output file");
    }
    my @files;
    opendir( my $dir, $folder );
    while ( my $file = readdir($dir) ) {
        if ( ( $file !~ /\.pod$/ ) or $file =~ /^\./ or $file =~ /^$output$/ ) {
            &Log::debug("Jumping to next file");
            next;
        }
        &Log::debug("Pushing to files array=>'$file'");
        push( @files, $file );
    }
    closedir $dir;
    open( my $pod, ">", $outfile );
    @files = sort { $a cmp $b } @files;
    foreach my $file (@files) {
        open( my $fh, "<", "$folder/$file" );
        my $data = do { local $/; <$fh> };
        close $fh;
        print $pod "\n" . $data;
    }
    close $pod;
    &Log::debug("Finishing Devel::create_mainpod sub");
    return 1;
}

1
