#!/usr/bin/perl
use strict;
use warnings;
use 5.14.0;
use Test::More;
use Test::Pod::Spelling::CommonMistakes;
use Test::Spelling;
add_stopwords(<DATA>);

all_pod_files_ok();
done_testing;
## Need to see how to handle some exceptions
__END__
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
savesessionfile
sessionfile
url
utf
vm
DNS
LOGLEVEL
wiki
CPAN
Dokuwiki
ESXi
README
SDK
STDOUT
VCenter
backend
balabit
bashrc
datastores
unmount
cp
criticise
shiftjis
login
iso
prereq
samu
portgroups
Krisztian
Banhidy
automatisation
Automatisation
username
cpu
desc
Portgroup
dvp
num
portnumber
vmname
vmware
servicepath
runtime
workgroup
cdroms
resourcepool
resourcepools
