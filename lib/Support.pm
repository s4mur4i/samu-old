package Support;

use strict;
use warnings;

BEGIN {
	use Exporter;
	our @ISA = qw(Exporter);
	our @EXPORT = qw( &test %template_hash %agents_hash );
	our @EXPORT_OK = qw( &test %template_hash %agents_hash );
}

### Tempalte name cannot contain '-' since regexes will fail matching to the name. '_' should be used instead
our %template_hash = (
	'scb_330' => { path => 'Support/vm/templates/SCB/3.3/3.3.0',  username => 'root', password => 'titkos', os=>'scb' },
	'scb_341' => { path => 'Support/vm/templates/SCB/3.4/3.4.1', username => 'root', password => 'titkos', os=>'scb' },
	'win7' => { path => 'Support/vm/templates/Windows/7/T_win_7_en_x64',username => 'admin', password => 'titkos', key=>'FJ82H-XT6CR-J8D7P-XQJJ2-GPDD4', os=>'win' },
	'deb_7.0.0_en_amd64' => {path => 'Support/vm/templates/Linux/deb/T_deb_7.0.0_en_amd64', username => 'root', password => 'titkos', os => 'other' },
);

our %agents_hash = (
	's4mur4i' => { mac=>'02:01:20:' },
	'balage' => { mac=>'02:01:19:' },
	'adrienn' => { mac=>'02:01:12:' },
	'varnyu' => { mac=>'02:01:40:' },
);

sub test() {
	print "test\n";
}

#### We need to end with success
1
