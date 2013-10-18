#!/usr/bin/perl
use strict;
use warnings;
use 5.14.0;
use Test::More;
use FindBin;
use English qw(-no_match_vars);
use lib "$FindBin::Bin/../lib";
use SAMU_Test::Common;

if ( !( $ENV{ALL} or $ENV{AUTHOR} ) ) {
    my $msg = 'Author test.  Set $ENV{AUTHOR} to a true value to run.';
    plan( skip_all => $msg );
}

eval { require Test::Files; };

if ($EVAL_ERROR) {
    my $msg = 'Test::Files required to criticise code';
    plan( skip_all => $msg );
}
Test::Files->import;

diag("Testing directory contents");
dir_only_contains_ok(
    "$FindBin::Bin/../vmware_lib/VMware",
    [
        qw(VICommon.pm VICredStore.pm VIExt.pm VILib.pm VIM25Runtime.pm VIM25Stub.pm VIM2Runtime.pm VIM2Stub.pm VIMRuntime.pm VIRuntime.pm)
    ],
    "VMware contains the Default modules only"
);
my $modules = &Test::module_namespace;
for my $module ( @$modules ) {
    if ( $module eq 'Pod') {
        # Pod is an external dependency and we dont do traditional testing with it
        next;
    }
    opendir( my $fh, "$FindBin::Bin/$module");
    my @files = grep { $_ ne '.' && $_ ne '..' && $_ !~ /_[^.]*\.t$/  } readdir $fh;
    closedir $fh;
    s/\.t$/\.pm/ foreach (@files);
    dir_only_contains_ok( "$FindBin::Bin/../lib/$module", \@files, "$module only contains tested modules");
}

dir_contains_ok(
    "$FindBin::Bin/../",
    [qw(samu.pl)],
    "Root only contains the default modules"
);

done_testing;
