package Support;

use strict;
use warnings;
use Data::Dumper;
use SDK::Vcenter;
use SDK::Misc;
use SDK::GuestManagement;
use SDK::Error;

BEGIN {
	use Exporter;
	our @ISA = qw( Exporter );
	our @EXPORT = qw( &test %template_hash %agents_hash &linked_clone_template_folder_path &generate_network_setup_for_clone &win_VirtualMachineCloneSpec &lin_VirtualMachineCloneSpec &oth_VirtualMachineCloneSpec );
}


sub linked_clone_template_folder_path {
	my ( $name ) = @_;
	Util::trace( 4, "Started Support::linked_clone_template_folder_path sub \n" );
	my $mo_ref;
	if ( !defined( $template_hash{$name} ) ) {
		SDK::Error::Entity::Path->throw( error => 'Could not retrieve path from template hash', path => $name );
	}
	if ( &Vcenter::exists_folder( $name ) ) {
	} else {
		Util::trace( 3, "Need to create the linked folder\n" );
		my $path = $template_hash{$name}{'path'};
		my $sc = Vim::get_service_content();
		if ( !defined( $sc ) ) {
			SDK::Error::Entity::ServiceContent->throw( error => 'Could not retrieve Service Content' );
		}
		my $searchindex = Vim::get_view( mo_ref => $sc->searchIndex );
		my $view = $searchindex->FindByInventoryPath( inventoryPath => $path );
		if ( !defined( $view ) ) {
			SDK::Error::Entity::Path->throw( error => 'Could not retrieve mo ref from path', path => $path );
		}
		$view = Vim::get_view( mo_ref => $view );
		my $parent_folder = Vim::get_view( mo_ref => $view->parent );
		&Vcenter::create_folder( $name, $parent_folder->name );
	}
	Util::trace( 4, "Finished Support::linked_clone_template_folder_path sub\n" );
}

sub generate_network_setup_for_clone {
	my ( $os ) = @_;
	Util::trace( 4, "Started Support::generate_network_setup_for_clone sub, os=>'$os'\n" );
	if ( defined( $template_hash{$os} ) ) {
		my @return;
		my $path = $template_hash{$os}{'path'};
		my $sc = Vim::get_service_content();
		if ( !defined( $sc ) ) {
			SDK::Error::Entity::ServiceContent->throw( error => 'Could not retrieve Service Content' );
		}
		my $searchindex = Vim::get_view( mo_ref => $sc->searchIndex );
		my $view = $searchindex->FindByInventoryPath( inventoryPath => $path );
		if ( !defined( $view ) ) {
			SDK::Error::Entity::Path->throw( error => 'Could not retrieve moref from path', path => $path );
		}
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
				Util::trace( 3, "Next interface mac address is $mac[ -1 ]\n" );
			}
		}
		for ( my $i =0;$i<@keys;$i++ ) {
			my $ethernetcard =VirtualE1000->new( addressType => 'Manual', macAddress => $mac[ $i ], wakeOnLanEnabled => 1, key => $keys[ $i ] );
			my $operation = VirtualDeviceConfigSpecOperation->new( 'edit' );
			my $deviceconfigspec = VirtualDeviceConfigSpec->new( device => $ethernetcard, operation => $operation );
			push( @return, $deviceconfigspec );
		}
		Util::trace( 4, "Finished Support::generate_network_setup_for_clone sub\n" );
		return \@return;
	} else {
		SDK::Error::Template::Exists->throw( error => 'Template does not exists', template => $os );
	}
}

sub win_VirtualMachineCloneSpec {
	my ( $os, $snapshot, $location, $config ) = @_;
	Util::trace( 4, "Started Support::win_VirtualMachineCloneSpec sub\n" );
	my $globalipsettings = CustomizationGlobalIPSettings->new( dnsServerList => [ '10.10.0.1' ] , dnsSuffixList => [ 'support.balabit' ] );
	my $customoptions = CustomizationWinOptions->new( changeSID => 1, deleteAccounts => 0 );
	my $custpass = CustomizationPassword->new( plainText => 1, value => 'titkos' );
	my $guiunattend = CustomizationGuiUnattended->new( autoLogon => 1, autoLogonCount => 1, password => $custpass, timeZone => '095' );
	my $customname = CustomizationPrefixName->new( base => 'winguest' );
	my $key =$template_hash{$os}{'key'} ;
	my $userdata = CustomizationUserData->new( productId => $key , orgName => 'support' , fullName => 'admin' , computerName => $customname );
	my $identification = CustomizationIdentification->new( domainAdmin => 'Administrator@support.balabit', domainAdminPassword => $custpass, joinDomain => 'support.balabit' );
	my $runonce = CustomizationGuiRunOnce->new( commandList => [ "w32tm /resync", "cscript c:/windows/system32/slmgr.vbs /skms prod-dev-winsrv.balabit", "cscript c:/windows/system32/slmgr.vbs /ato" ] );
	my @nicsetting = &GuestManagement::CustomizationAdapterMapping_generator( $os );
	my $identity;
	if ( ( $os =~ /^win_2003/ ) || ( $os =~ /^win_2000/ ) ) {
		Util::trace( 3, "Win2k3 and Win2k licensing workaround\n" );
		my $automode = CustomizationLicenseDataMode->new( 'perSeat' );
		my $licenseprintdata =  CustomizationLicenseFilePrintData->new( autoMode => $automode );
		$identity = CustomizationSysprep->new( guiRunOnce => $runonce, guiUnattended => $guiunattend, identification => $identification , userData => $userdata, licenseFilePrintData => $licenseprintdata );
	} else {
		Util::trace( 3, "No license file generation required\n" );
		$identity = CustomizationSysprep->new( guiRunOnce => $runonce, guiUnattended => $guiunattend, identification => $identification , userData => $userdata );
	}
	my $customization_spec = CustomizationSpec->new( globalIPSettings => $globalipsettings, identity => $identity, options => $customoptions, nicSettingMap => @nicsetting );
	my $clone_spec = VirtualMachineCloneSpec->new( powerOn => 1, template => 0, snapshot => $snapshot, location => $location, config => $config, customization => $customization_spec );
	Util::trace ( 4, "Finished Support::win_VirtualMachineCloneSpec sub\n" );
	return $clone_spec;
}

sub lin_VirtualMachineCloneSpec {
	my ( $os, $snapshot, $location, $config ) = @_;
	Util::trace( 4, "Started Support::lin_VirtualMachineCloneSpec sub\n" );
	my @nicsetting = &GuestManagement::CustomizationAdapterMapping_generator( $os );
	my $hostname = CustomizationPrefixName->new( base => 'linuxguest' );
	my $globalipsettings = CustomizationGlobalIPSettings->new( dnsServerList => [ '10.10.0.1' ] , dnsSuffixList => [ 'support.balabit' ] );
	my $linuxprep = CustomizationLinuxPrep->new( domain => 'support.balabit', hostName => $hostname, timeZone => 'Europe/Budapest', hwClockUTC => 1 );
	my $customization_spec = CustomizationSpec->new( identity => $linuxprep, globalIPSettings => $globalipsettings, nicSettingMap => @nicsetting );
	my $clone_spec = VirtualMachineCloneSpec->new( powerOn => 1, template => 0, snapshot => $snapshot, location => $location, config => $config, customization => $customization_spec );
	Util::trace ( 4, "Finished Support::lin_VirtualMachineCloneSpec sub\n" );
	return $clone_spec;
}

sub oth_VirtualMachineCloneSpec {
	my ( $os, $snapshot, $location, $config ) = @_;
	Util::trace( 4, "Started Support::oth_VirtualMachineCloneSpec sub\n" );
	my $clone_spec = VirtualMachineCloneSpec->new( powerOn => 1, template => 0, snapshot => $snapshot, location => $location, config => $config );
	Util::trace ( 4, "Finished Support::oth_VirtualMachineCloneSpec sub\n" );
	return $clone_spec;
}

## Functionality test sub
sub test( ) {
	Util::trace( 4, "Started Support::test sub\n" );
	Util::trace( 0, "Support module test sub\n" );
	Util::trace( 4, "Finished Support::test \n" );
}

#### We need to end with success
1
