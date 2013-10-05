#!/usr/bin/env perl
#===============================================================================
#
#         FILE: create_mainpod.pl
#
#        USAGE: ./create_mainpod.pl
#
#  DESCRIPTION: Creates the main.pod file from all other files
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Banhidy Krisztian (s4mur4i), s4mur4i@balabit.hu
# ORGANIZATION: Support
#      VERSION: 1.0
#      CREATED: 10/05/2013 11:32:23 AM
#     REVISION: ---
#===============================================================================

use strict;
use warnings;
use FindBin;
my @files;
my $doc_path = "$FindBin::Bin/doc";
opendir( my $dir, $doc_path );
while ( my $file = readdir($dir) ) {
    if ( ( !$file =~ /^\d{2}_/ ) or $file =~ /^\./ or $file =~ /^m/ ) {

        #       print "Skipping $file\n";
        next;
    }

    #    print $file . "\n";
    push( @files, $file );
}
closedir $dir;
open( my $pod, ">", "$doc_path/main.pod" );
@files = sort { $a cmp $b } @files;
foreach my $file (@files) {
    open( my $fh, "<", "$FindBin::Bin/doc/$file" );
    my $data = do { local $/; <$fh> };
    close $fh;
    print $pod "\n" . $data;
}
close $pod
