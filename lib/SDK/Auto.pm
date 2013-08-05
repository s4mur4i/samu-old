package Auto;

use strict;
use warnings;
use Data::Dumper;
use SDK::GuestInternal;

BEGIN {
        use Exporter;
        our @ISA = qw( Exporter );
        our @EXPORT = qw( &test %dns &install_puppet );
}

our %dns = (
	prod_ad => { vmname => 'DC_PROD', username => 'Administrator@ittest.balabit', password => 'Password123', domain => 'ittest.balabit' },
	dev_ad => { vmname => 'DC-DEV', username => 'Administrator@support.balabit', password => 'titkos', domain => 'support.balabit' },
);

sub list_dns {
	my ( $zone ) = @_;
	my $workdir='c:\\';
	my $env='PATH=C:\windows\system32';
	my $prog='C:\windows\system32\cmd.exe';
	my $arg = "/c dnscmd /zoneprint $dns{$zone}{'domain'} >C:/dns.out";
	&GuestInternal::runCommandInGuest( $dns{$zone}{'vmname'}, $prog, $arg, $env, $workdir, $dns{$zone}{'username'}, $dns{$zone}{'password'} );
	&GuestInternal::transfer_from_guest( $dns{$zone}{'vmname'}, 'C:\dns.out', "/tmp/dns.out", $dns{$zone}{'username'}, $dns{$zone}{'password'} );
	open ( my $fh, "/tmp/dns.out" );
	while ( my $line = <$fh> ) {
		chomp $line;
		if ( $line !~ /^\s*[_;]/ and $line !~ /^\s*$/ ) {
			print $line ."\n";
		}
	}
	close $fh;
}

sub install_puppet {
	my ( $vmname ) = @_;
}

sub test() {
        print "Automatisation module test sub\n";
}

#### We need to end with success
1
