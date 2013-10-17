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
find( sub{  if ( $File::Find::name =~ /\.pm$/) { push(@files, $File::Find::name)}  }, $dir);
my $extor = Module::Extract::Use->new;
my @modules;
for my $file ( @files ) {
    my $info = $extor->get_modules_with_details($file);
    for my $module ( @$info ) {
        if  ( ($module->{module} =~ /^[^ :]*::/) and ( $module->{module} !~ /^(BB|Base|VMware|SAMU_Test|Win32)::/) ) {
            push(@modules, $module->{module});
        }
    }
}
@modules = &Test::uniq(@modules);
diag("Extracted modules");

for my $module (@modules) {
    is( &Test::search_file( "$FindBin::Bin/../Makefile.PL", "$module"),1, "$module is in Makefile.PL" );
}
done_testing;
