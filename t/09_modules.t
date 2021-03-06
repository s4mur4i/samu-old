#!/usr/bin/perl
use strict;
use warnings;
use 5.14.0;
use FindBin;
use File::Find;
use Module::Extract::Use;
use Test::More;
use lib "$FindBin::Bin/../lib";
use SAMU_Test::Common;

my $dir = "$FindBin::Bin/../";
my @files;
my @testfiles;
find(
    sub {
        if ( $File::Find::name =~ /\.pm$/ ) {
            push( @files, $File::Find::name );
        }
    },
    $dir
);
find(
    sub {
        if ( $File::Find::name =~ /\.t$/ ) {
            push( @testfiles, $File::Find::name );
        }
    },
    $dir
);
my $extor = Module::Extract::Use->new;
my @modules;
my @testmodules;
for my $file (@files) {
    my $info = $extor->get_modules_with_details($file);
    for my $module (@$info) {
        if (    ( $module->{module} =~ /^[^ :]*::/ )
            and ( $module->{module} !~ /^(BB|Base|VMware|SAMU_Test|Win32)::/ ) )
        {
            push( @modules, $module->{module} );
        }
    }
}
for my $file (@testfiles) {
    my $info = $extor->get_modules_with_details($file);
    for my $module (@$info) {
        if (    ( $module->{module} =~ /^[^ :]*::/ )
            and ( $module->{module} !~ /^(BB|Base|VMware|SAMU_Test|Win32)::/ ) )
        {
            push( @testmodules, $module->{module} );
        }
    }
}

@modules     = &Test::uniq(@modules);
@testmodules = &Test::uniq(@testmodules);
diag("Modules Extracted");
diag("Normal modules");
for my $module (@modules) {
    is( &Test::search_file( "$FindBin::Bin/../Makefile.PL", "$module" ),
        1, "$module is in Makefile.PL" );
}
diag("Test modules");
for my $module (@testmodules) {
    is( &Test::search_file( "$FindBin::Bin/../Makefile.PL", "$module" ),
        1, "$module is in Makefile.PL" );
}
my %make_modules = ();
open(my $fh, "<", "$FindBin::Bin/../Makefile.PL");
while ( my $line = <$fh>) {
    chomp $line;
    if ( $line =~ /^\s*'[^:]*(:{2}[^:]*)'\s*=>\s*[^,]*,\s*$/ ) {
        my ($mod) = $line =~ /'([^']*)'/;
        $make_modules{$mod} = 1;
    }
}
my %modules = map { $_ => 1 } @modules;
my %testmodules = map { $_ => 1 } @testmodules;
my %mergedmodules = ( %modules, %testmodules);
close $fh;
for my $mod ( keys %make_modules ) {
    is( $mergedmodules{$mod} // 0, 1, "$mod is used");
}
done_testing;
