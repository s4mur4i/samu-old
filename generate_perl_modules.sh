#!/bin/bash
file="PERL_MODULES"
## generate normal modules
egrep -Rh ^use\s*[^:]*::[^:]* * | perl -ne 'chomp $_ ;my ( $var ) = $_ =~ /^use\s*([^ :]*::[^: ;]*)[ ;]?/;if ($var ne "" ) { print "$var\n" }' |grep -ve VMware -ve AppUtil -ve SDK|sort -u > $file
## generate single module
egrep -Rh "^use\s*[^: ]*[\s;]+"| sort -u|grep -ve strict -ve warnings -ve constant| perl -ne 'chomp $_ ; my ($var) = $_ =~ /^use\s*([^ ;]*)/; if ( $var ne "" ) {print "$var\n"}' |grep -v 5.006001 >> $file
## static module
echo "DBD::mysql" >> $file
