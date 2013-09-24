#!/bin/bash
file="PERL_MODULES"
## generate normal modules
egrep -Rh "^use\s*[^:]*::[^: ]*|require\s*[^:]*::[^: ]*" * | perl -ne 'chomp $_ ;my ( $var ) = $_ =~ /([^ :]*::[^: ;]*)/;if ($var ne "" ) { print "$var\n" }' |egrep -v 'VMware|AppUtil|SDK|BB|Base|FindBin|Vim|Win32|GSSAPI|Test::Perl' |sort -u > $file
## generate single module
egrep -Rh "^use\s*[^: ]*[\s;]+$" * | sort -u|egrep -v "strict|warnings|constant|5." | perl -ne 'chomp $_ ; my ($var) = $_ =~ /^use\s*([^ ;]*)/; if ( $var ne "" ) {print "$var\n"}' >> $file
## static module
echo "DBD::mysql" >> $file
echo "Test::Perl::Critic" >> $file
echo "Pod::Simple::Wiki" >> $file
