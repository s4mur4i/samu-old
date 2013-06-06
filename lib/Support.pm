package Support;

use strict;
use warnings;

BEGIN {
	use Exporter;
	our @ISA = qw(Exporter);
	our @EXPORT = qw( &test %template_hash );
	our @EXPORT_OK = qw( &test %template_hash );
}

### Tempalte name cannot contain '-' since regexes will fail matching to the name. '_' should be used instead
our %template_hash = (
	'scb_330' => { path => 'Support/vm/templates/SCB/3.3/3.3.0',  username => 'root', password => 'titkos'},
	'scb_341' => { path => 'Support/vm/templates/SCB/3.4/3.4.1', username => 'root', password => 'titkos'},
	'win7' => {path => 'Support/vm/templates/Windows/7/T_win_7_en_x64',username => 'admin', password => 'titkos'},
);
sub test() {
	print "test\n";
}

#### We need to end with success
1
