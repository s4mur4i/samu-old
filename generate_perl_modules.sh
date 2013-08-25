#!/bin/bash
file="PERL_MODULES"
## generate normal modules
egrep -Rh ^use\s*[^:]*::[^:]* * | perl -ne 'chomp $_ ;my ( $var ) = $_ =~ /^use\s*([^ :]*::[^: ;]*)[ ;]?/;if ($var ne "" ) { print "$var\n" }' |egrep -v 'VMware|AppUtil|SDK|BB|Base' |sort -u > $file
## generate single module
egrep -Rh "^use\s*[^: ]*[\s;]+$"| sort -u|egrep -v "strict|warnings|constant" | perl -ne 'chomp $_ ; my ($var) = $_ =~ /^use\s*([^ ;]*)/; if ( $var ne "" ) {print "$var\n"}' >> $file
## static module
echo "DBD::mysql" >> $file
