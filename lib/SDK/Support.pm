package Support;

use strict;
use warnings;
use Data::Dumper;
use SDK::Vcenter;
use SDK::Misc;
use SDK::GuestManagement;

BEGIN {
	use Exporter;
	our @ISA = qw( Exporter );
	our @EXPORT = qw( &test %template_hash %agents_hash &linked_clone_template_folder_path &generate_network_setup_for_clone &win_VirtualMachineCloneSpec &lin_VirtualMachineCloneSpec &oth_VirtualMachineCloneSpec );
}

## Information about templates and attributes used
our %template_hash = (
	'scb_300' => { path => 'Support/vm/templates/SCB/3.0/T_scb_300',  username => 'root', password => 'titkos', os => 'scb' },
	'scb_330' => { path => 'Support/vm/templates/SCB/3.3/T_scb_330',  username => 'root', password => 'titkos', os => 'scb' },
	'scb_341' => { path => 'Support/vm/templates/SCB/3.4/T_scb_341', username => 'root', password => 'titkos', os => 'scb' },
	'scb_342' => { path => 'Support/vm/templates/SCB/3.4/T_scb_342', username => 'root', password => 'titkos', os => 'scb' },
	'win_xpsp2_en_x64_pro' => { path => 'Support/vm/templates/Windows/xp/T_win_xpsp2_en_x64_pro', username => 'admin', password => 'titkos', key => 'T76MT-KCXJW-Y8J2V-PRQVQ-3B9WQ', os => 'win' },
	'win_7_en_x64_pro' => { path => 'Support/vm/templates/Windows/7/T_win_7_en_x64_pro', username => 'admin', password => 'titkos', key => 'FJ82H-XT6CR-J8D7P-XQJJ2-GPDD4', os => 'win' },
	'win_7_en_x86_ent' => { path => 'Support/vm/templates/Windows/7/T_win_7_en_x86_ent', username => 'admin', password => 'titkos', key => '33PXH-7Y6KF-2VJC9-XBBR8-HVTHH', os => 'win' },
	'win_2003_en_x64_ent' => { path => 'Support/vm/templates/Windows/2003/T_win_2003_en_x64_ent', username => 'Administrator', password => 'titkos', key => 'T7RC2-XJ6DF-TBJ3B-KRR6F-898YG', os => 'win' },
	'win_2008_en_x64_sta' => { path => 'Support/vm/templates/Windows/2008/T_win_2008_en_x64_sta', username => 'Administrator', password => 'titkos', key => 'TM24T-X9RMF-VWXK6-X8JC9-BFGM2', os => 'win' },
	'deb_7.0.0_en_amd64_wheezy' => { path => 'Support/vm/templates/Linux/deb/T_deb_7.0.0_en_amd64_wheezy', username => 'root', password => 'titkos', os => 'other' },
	'deb_6.0.0_en_amd64_squeeze' => { path => 'Support/vm/templates/Linux/deb/T_deb_6.0.0_en_amd64_squeeze', username => 'root', password => 'titkos', os => 'other' },
	'win_2008r2_en_x64_sta' => { path => 'Support/vm/templates/Windows/2008/T_win_2008r2_en_x64_sta', username => 'Administrator', password => 'titkos', key => 'YC6KT-GKW9T-YTKYR-T4X34-R7VHC', os => 'win' },
	'win_2008r2sp1_en_x64_sta' => { path => 'Support/vm/templates/Windows/2008/T_win_2008r2sp1_en_x64_sta', username => 'Administrator', password => 'TitkoS12', key => 'YC6KT-GKW9T-YTKYR-T4X34-R7VHC', os => 'win' },
	'cent_6.4_en_i386_cent64' => { path => 'Support/vm/templates/Linux/cent/T_cent_6.4_en_i386_cent64', username => 'root', password => 'titkos', os => 'other' },
	'cent_6.4_en_amd64_cent64' => { path => 'Support/vm/templates/Linux/cent/T_cent_6.4_en_amd64_cent64', username => 'root', password => 'titkos', os => 'other' },
);

## Agent information for scripts
our %agents_hash = (
	's4mur4i' => { mac => '02:01:20:' },
	'balage' => { mac => '02:01:12:' },
	'adrienn' => { mac => '02:01:19:' },
	'varnyu' => { mac => '02:01:19:' },
);

sub linked_clone_template_folder_path {
	my ( $name ) = @_;
	my $mo_ref;
	if ( !defined( $template_hash{$name} ) ) {
		print "Cannot find path for os: $name\n";
	}
	if ( &Vcenter::exists_folder( $name ) ) {
		print "Linked folder exists already\n";
		$mo_ref = Vim::find_entity_view( view_type => 'Folder', filter => {name => $name} );
	} else {
		print "Need to create the linked folder.\n";
		my $path = $template_hash{$name}{'path'};
		my $sc = Vim::get_service_content( );
		my $searchindex = Vim::get_view( mo_ref => $sc->searchIndex );
		my $view = $searchindex->FindByInventoryPath( inventoryPath => $path );
		$view = Vim::get_view( mo_ref => $view );
		my $parent_folder = Vim::get_view( mo_ref => $view->parent );
		$mo_ref =  &Vcenter::create_folder( $name, $parent_folder->name );
	}
}

sub generate_network_setup_for_clone {
	my ( $os ) = @_;
	my @return;
	if ( defined( $template_hash{$os} ) ) {
		my $path = $template_hash{$os}{'path'};
		my $sc = Vim::get_service_content( );
		my $searchindex = Vim::get_view( mo_ref => $sc->searchIndex );
		my $view = $searchindex->FindByInventoryPath( inventoryPath => $path );
		my $template_mo_ref = Vim::get_view( mo_ref => $view );
		my @keys;
		foreach ( @{$template_mo_ref->config->hardware->device} ) {
			my $interface = $_;
			if ( !$interface->isa( 'VirtualE1000' ) ) {
				next;
			}
			push( @keys, $interface->key )
		}
		my @mac;
		while ( @mac != @keys ) {
			push( @mac, &Misc::generate_uniq_mac );
			for ( my $i =1;$i<@keys;$i++ ) {
				my $last =$mac[ -1 ];
				my $new_mac = &Misc::increment_mac( $last );
				push( @mac, $new_mac );
				print "Next interface mac address is $mac[ -1 ]\n";
			}
		}
		for ( my $i =0;$i<@keys;$i++ ) {
			my $ethernetcard =VirtualE1000->new( addressType => 'Manual', macAddress => $mac[ $i ], wakeOnLanEnabled => 1, key => $keys[ $i ] );
			my $operation = VirtualDeviceConfigSpecOperation->new( 'edit' );
			my $deviceconfigspec = VirtualDeviceConfigSpec->new( device => $ethernetcard, operation => $operation );
			push( @return, $deviceconfigspec );
		}
	} else {
		print "No such template\n";
		return 0;
	}
	return \@return;
}

sub win_VirtualMachineCloneSpec {
	my ( $os, $snapshot, $location, $config ) = @_;
	print "Running Windows Sysprep\n";
	my $globalipsettings = CustomizationGlobalIPSettings->new( dnsServerList => [ '10.21.0.23' ] , dnsSuffixList => [ 'support.balabit' ] );
	my $customoptions = CustomizationWinOptions->new( changeSID => 1, deleteAccounts => 0 );
	my $custpass = CustomizationPassword->new( plainText => 1, value => 'titkos' );
	my $guiunattend = CustomizationGuiUnattended->new( autoLogon => 1, autoLogonCount => 1, password => $custpass, timeZone => '095' );
	my $customname = CustomizationPrefixName->new( base => 'winguest' );
	my $key =$template_hash{$os}{'key'} ;
	my $userdata = CustomizationUserData->new( productId => $key , orgName => 'support' , fullName => 'admin' , computerName => $customname );
	my $identification = CustomizationIdentification->new( domainAdmin => 'Administrator@support.balabit', domainAdminPassword => $custpass, joinDomain => 'support.balabit.' );
	my $runonce = CustomizationGuiRunOnce->new( commandList => [ "w32tm /resync", "cscript c:/windows/system32/slmgr.vbs /skms prod-dev-winsrv.balabit", "cscript c:/windows/system32/slmgr.vbs /ato" ] );
	my @nicsetting = &GuestManagement::CustomizationAdapterMapping_generator( $os );
	## Workaround for Win 2000 and 2003 licensing
	my $identity;
	if ( ( $os =~ /^win_2003/ ) || ( $os =~ /^win_2000/ ) ) {
		print "Win 2k/2k3 licensing workaround.\n";
		my $automode = CustomizationLicenseDataMode->new( 'perSeat' );
		my $licenseprintdata =  CustomizationLicenseFilePrintData->new( autoMode => $automode );
		$identity = CustomizationSysprep->new( guiRunOnce => $runonce, guiUnattended => $guiunattend, identification => $identification , userData => $userdata, licenseFilePrintData => $licenseprintdata );
	} else {
		$identity = CustomizationSysprep->new( guiRunOnce => $runonce, guiUnattended => $guiunattend, identification => $identification , userData => $userdata );
	}
	my $customization_spec = CustomizationSpec->new( globalIPSettings => $globalipsettings, identity => $identity, options => $customoptions, nicSettingMap => @nicsetting );
	my $clone_spec = VirtualMachineCloneSpec->new( powerOn => 1, template => 0, snapshot => $snapshot, location => $location, config => $config, customization => $customization_spec );
	return $clone_spec;
}

sub lin_VirtualMachineCloneSpec {
	my ( $os, $snapshot, $location, $config ) = @_;
	print "Running Linux Sysprep\n";
	my @nicsetting = &GuestManagement::CustomizationAdapterMapping_generator( $os );
	my $hostname = CustomizationPrefixName->new( base => 'linuxguest' );
	my $globalipsettings = CustomizationGlobalIPSettings->new( dnsServerList => [ '10.21.0.23' ] , dnsSuffixList => [ 'support.balabit' ] );
	my $linuxprep = CustomizationLinuxPrep->new( domain => 'support.balabit', hostName => $hostname, timeZone => 'Europe/Budapest', hwClockUTC => 1 );
	my $customization_spec = CustomizationSpec->new( identity => $linuxprep, globalIPSettings => $globalipsettings, nicSettingMap => @nicsetting );
	my $clone_spec = VirtualMachineCloneSpec->new( powerOn => 1, template => 0, snapshot => $snapshot, location => $location, config => $config, customization => $customization_spec );
	return $clone_spec;
}

sub oth_VirtualMachineCloneSpec {
	my ( $os, $snapshot, $location, $config ) = @_;
	my $clone_spec = VirtualMachineCloneSpec->new( powerOn => 1, template => 0, snapshot => $snapshot, location => $location, config => $config );
	return $clone_spec;
}

## Functionality test sub
sub test( ) {
	print "Support module test sub\n";
}

#### We need to end with success
1
