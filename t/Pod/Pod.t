#!/usr/bin/perl
use strict;
use warnings;
use 5.14.0;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../../lib";
use Test::Pod::Spelling::CommonMistakes;
use Test::Spelling;
add_stopwords(<DATA>);
BEGIN { use_ok('Pod::Simple::Wiki::Dokuwiki'); }

ok( -e "$FindBin::Bin/../../doc/main.pod", "Main.pod exists" );
diag("Testing Pod file");
pod_file_ok("$FindBin::Bin/../../doc/main.pod");
pod_file_spelling_ok( "$FindBin::Bin/../../doc/main.pod",
    'POD file spelling OK' );
done_testing;
## Need to see how to handle some exceptions
__END__
vv
vvv
DATASTORE
KAYAKO
TBD
VM
altername
bugzilla
cdrom
credstore
datastore
https
kayako
passthroughauth
passthroughauthpackage
portnumber
runtime
savesessionfile
servicepath
sessionfile
url
username
utf
vm
DNS
LOGLEVEL
