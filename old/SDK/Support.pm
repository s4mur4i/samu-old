
sub generate_network_setup_for_clone {
	my ( $os ) = @_;
	if ( defined( $template_hash{$os} ) ) {
		my @return;
		my $path = $template_hash{$os}{'path'};
		my $sc = Vim::get_service_content();
		if ( !defined( $sc ) ) {
		}
		my $searchindex = Vim::get_view( mo_ref => $sc->searchIndex );
		my $view = $searchindex->FindByInventoryPath( inventoryPath => $path );
		if ( !defined( $view ) ) {
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
			}
		}
		for ( my $i =0;$i<@keys;$i++ ) {
			my $ethernetcard =VirtualE1000->new( addressType => 'Manual', macAddress => $mac[ $i ], wakeOnLanEnabled => 1, key => $keys[ $i ] );
			my $operation = VirtualDeviceConfigSpecOperation->new( 'edit' );
			my $deviceconfigspec = VirtualDeviceConfigSpec->new( device => $ethernetcard, operation => $operation );
			push( @return, $deviceconfigspec );
		}
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
