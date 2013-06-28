package Support;

use strict;
use warnings;
use Data::Dumper;

BEGIN {
        use Exporter;
        our @ISA = qw(Exporter);
        our @EXPORT = qw( &test %template_hash %agents_hash );
        our @EXPORT_OK = qw( &test %template_hash %agents_hash );
}

## Information about templates and attributes used
our %template_hash = (
        'scb_300' => { path => 'Support/vm/templates/SCB/3.0/T_scb_300',  username => 'root', password => 'titkos', os=>'scb' },
        'scb_330' => { path => 'Support/vm/templates/SCB/3.3/T_scb_330',  username => 'root', password => 'titkos', os=>'scb' },
        'scb_341' => { path => 'Support/vm/templates/SCB/3.4/T_scb_341', username => 'root', password => 'titkos', os=>'scb' },
        'win_xpsp2_en_x64_pro' => { path => 'Support/vm/templates/Windows/xp/T_win_xpsp2_en_x64_pro',username => 'admin', password => 'titkos', key=>'T76MT-KCXJW-Y8J2V-PRQVQ-3B9WQ', os=>'win' },
        'win_7_en_x64_pro' => { path => 'Support/vm/templates/Windows/7/T_win_7_en_x64_pro',username => 'admin', password => 'titkos', key=>'FJ82H-XT6CR-J8D7P-XQJJ2-GPDD4', os=>'win' },
        'win_7_en_x86_ent' => { path => 'Support/vm/templates/Windows/7/T_win_7_en_x86_ent',username => 'admin', password => 'titkos', key=>'33PXH-7Y6KF-2VJC9-XBBR8-HVTHH', os=>'win' },
        'win_2003_en_x64_ent' => { path => 'Support/vm/templates/Windows/2003/T_win_2003_en_x64_ent',username => 'Administrator', password => 'titkos', key=>'T7RC2-XJ6DF-TBJ3B-KRR6F-898YG', os=>'win' },
        'win_2008_en_x64_sta' => { path => 'Support/vm/templates/Windows/2008/T_win_2008_en_x64_sta',username => 'Administrator', password => 'TitkoS12', key=>'TM24T-X9RMF-VWXK6-X8JC9-BFGM2', os=>'win' },
        'deb_7.0.0_en_amd64_wheezy' => {path => 'Support/vm/templates/Linux/deb/T_deb_7.0.0_en_amd64_wheezy', username => 'root', password => 'titkos', os => 'other' },
);

## Agent information for scripts
our %agents_hash = (
        's4mur4i' => { mac=>'02:01:20:' },
        'balage' => { mac=>'02:01:12:' },
        'adrienn' => { mac=>'02:01:19:' },
        'varnyu' => { mac=>'02:01:19:' },
);

## Functionality test sub
sub test() {
        print "Support module test sub\n";
}

#### We need to end with success
1
