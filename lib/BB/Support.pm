package Support;

use strict;
use warnings;

BEGIN {
    use Exporter;
    our @ISA    = qw( Exporter );
    our @EXPORT = qw( );
}

=pod

=head1 template_hash

=head2 description

    This hash contains information about our templates.
=cut

my %template_hash = (
    'scb_300' => {
        path     => 'Support/vm/templates/SCB/scb_3.0/T_scb_300',
        username => 'root',
        password => 'titkos',
        os       => 'scb'
    },
    'scb_330' => {
        path     => 'Support/vm/templates/SCB/scb_3.3/T_scb_330',
        username => 'root',
        password => 'titkos',
        os       => 'scb'
    },
    'scb_341' => {
        path     => 'Support/vm/templates/SCB/3.4/T_scb_341',
        username => 'root',
        password => 'titkos',
        os       => 'scb'
    },
    'scb_342' => {
        path     => 'Support/vm/templates/SCB/3.4/T_scb_342',
        username => 'root',
        password => 'titkos',
        os       => 'scb'
    },
    'scb_350' => {
        path     => 'Support/vm/templates/SCB/3.5/T_scb_350',
        username => 'root',
        password => 'titkos',
        os       => 'scb'
    },
    'win_7_en_x64_pro' => {
        path     => 'Support/vm/templates/Windows/7/T_win_7_en_x64_pro',
        username => 'admin',
        password => 'titkos',
        key      => 'FJ82H-XT6CR-J8D7P-XQJJ2-GPDD4',
        os       => 'win'
    },
    'win_7_en_x86_ent' => {
        path     => 'Support/vm/templates/Windows/7/T_win_7_en_x86_ent',
        username => 'admin',
        password => 'titkos',
        key      => '33PXH-7Y6KF-2VJC9-XBBR8-HVTHH',
        os       => 'win'
    },
    'win_2003_en_x64_ent' => {
        path     => 'Support/vm/templates/Windows/2003/T_win_2003_en_x64_ent',
        username => 'Administrator',
        password => 'titkos',
        key      => 'T7RC2-XJ6DF-TBJ3B-KRR6F-898YG',
        os       => 'win'
    },
    'win_2008_en_x64_sta' => {
        path     => 'Support/vm/templates/Windows/2008/T_win_2008_en_x64_sta',
        username => 'Administrator',
        password => 'TitkoS12',
        key      => 'TM24T-X9RMF-VWXK6-X8JC9-BFGM2',
        os       => 'win'
    },
    'win_2008_en_x86_ent' => {
        path     => 'Support/vm/templates/Windows/2008/T_win_2008_en_x86_ent',
	username => 'Administrator',
	password => 'TitkoS12',
	key      => 'YQGMW-MPWTJ-34KDK-48M3W-X4Q6V',
	os       => 'win'
    },
    'deb_7.0.0_en_amd64_wheezy' => {
        path => 'Support/vm/templates/Linux/deb/T_deb_7.0.0_en_amd64_wheezy',
        username => 'root',
        password => 'titkos',
        os       => 'other'
    },
    'deb_6.0.0_en_amd64_squeeze' => {
        path => 'Support/vm/templates/Linux/deb/T_deb_6.0.0_en_amd64_squeeze',
        username => 'root',
        password => 'titkos',
        os       => 'other'
    },
    'win_2008r2_en_x64_sta' => {
        path     => 'Support/vm/templates/Windows/2008/T_win_2008r2_en_x64_sta',
        username => 'Administrator',
        password => 'TitkoS12',
        key      => 'YC6KT-GKW9T-YTKYR-T4X34-R7VHC',
        os       => 'win'
    },
    'win_2008r2_en_x64_stadeb' => {
        path => 'Support/vm/templates/Windows/2008/T_win_2008r2_en_x64_stadeb',
        username => 'Administrator',
        password => 'TitkoS12',
        key      => 'YC6KT-GKW9T-YTKYR-T4X34-R7VHC',
        os       => 'win'
    },
    'win_2008r2_en_x64_ent' => {
        path     => 'Support/vm/templates/Windows/2008/T_win_2008r2_en_x64_ent',
        username => 'Administrator',
        password => 'TitkoS12',
        key      => '489J6-VHDMP-X63PK-3K798-CPX3Y',
        os       => 'win'
    },
    'win_2008r2sp1_en_x64_sta' => {
        path => 'Support/vm/templates/Windows/2008/T_win_2008r2sp1_en_x64_sta',
        username => 'Administrator',
        password => 'TitkoS12',
        key      => 'YC6KT-GKW9T-YTKYR-T4X34-R7VHC',
        os       => 'win'
    },
    'cent_6.0_en_amd64_cent64' => {
        path => 'Support/vm/templates/Linux/cent/T_cent_6.0_en_amd64_cent64',
        username => 'root',
        password => 'titkos',
        os       => 'other'
    },
    'cent_6.4_en_i386_cent64' => {
        path     => 'Support/vm/templates/Linux/cent/T_cent_6.4_en_i386_cent64',
        username => 'root',
        password => 'titkos',
        os       => 'other'
    },
    'cent_6.4_en_amd64_cent64' => {
        path => 'Support/vm/templates/Linux/cent/T_cent_6.4_en_amd64_cent64',
        username => 'root',
        password => 'titkos',
        os       => 'other'
    },
    'oracle_5.6_en_x64_ent' => {
        path     => 'Support/vm/templates/Linux/oracle/T_oracle_5.6_en_x64_ent',
        username => 'root',
        password => 'titkos',
        os       => 'other'
    },
    'rhel_6.0_en_amd64_rhel60' => {
        path => 'Support/vm/templates/Linux/rhel/T_rhel_6.0_en_amd64_rhel60',
        username => 'root',
        password => 'titkos',
        os       => 'other'
    },
    'ubuntu_12.04.3_en_amd64_sta' => {
        path =>
          'Support/vm/templates/Linux/ubuntu/T_ubuntu_12.04.3_en_amd64_sta',
        username => 'root',
        password => 'titkos',
        os       => 'other',
    },
    'ubuntu_10.04_en_amd64_sta' => {
        path => 'Support/vm/templates/Linux/ubuntu/T_ubuntu_10.04_en_amd64_sta',
        username => 'root',
        password => 'titkos',
        os       => 'other'
    },
);

my %agents_hash = (
    's4mur4i' => { mac => '02:01:20:' },
    'balage'  => { mac => '02:01:12:' },
    'adrienn' => { mac => '02:01:19:' },
    'varnyu'  => { mac => '02:01:19:' },
    'kkovari' => { mac => '02:01:00:' },
    'szaki'   => { mac => '02:01:00:' },
    'blehel'  => { mac => '02:01:00:' },
    'imre'    => { mac => '02:01:00:' },
);

my %map_hash = (
    'agents'   => \%agents_hash,
    'template' => \%template_hash,
);

=pod

=head2 template_keys

=head3 arguments

=head3 return

=head3 exception

=cut

#tested
sub get_keys {
    my ($hash) = @_;
    &Log::debug("Starting Support::get_keys sub, hash=>'$hash'");
    if ( !defined( $map_hash{$hash} ) ) {
        Template::Status->throw(
            error    => 'Requested hash_map was not found',
            template => $hash
        );
    }
    my $req_hash = $map_hash{$hash};
    return [ keys %$req_hash ];
}

=pod

=head2 get_key_info

=head3 arguments

=item template

=head3 return

=head3 exception

=cut

#tested
sub get_key_info {
    my ( $hash, $key ) = @_;
    &Log::debug(
        "Starting Support::get_key_info sub, hash=>'$hash', key=>'$key'");
    if ( grep /^$key$/, @{ &get_keys($hash) } ) {
        return $map_hash{$hash}->{$key};
    }
    else {
        Template::Status->throw(
            error    => 'Requested key info was not found',
            template => $key
        );
    }
}

#tested
sub get_key_value {
    my ( $hash, $key, $value ) = @_;
    &Log::debug(
"Starting Support::get_key_value sub, hash=>'$hash', key=>'$key', value=>'$value'"
    );
    my $key_hash = &get_key_info( $hash, $key );
    if ( defined( $$key_hash{$value} ) ) {
        return $$key_hash{$value};
    }
    else {
        Template::Status->throw(
            error    => 'Requested key value was not found',
            template => $value
        );
    }
}

### Installation helper objects
#tested
sub RelocateSpec {
    my ($ticket) = @_;
    &Log::debug("Starting Support::RelocateSpec sub, ticket=>'$ticket'");
    my $host_view =
      &Guest::entity_name_view( 'vmware-it1.balabit', 'HostSystem' );
    my $ticket_resource_pool =
      &Guest::entity_name_view( $ticket, 'ResourcePool' );
    my $relocate_spec = VirtualMachineRelocateSpec->new(
        host         => $host_view,
        diskMoveType => "createNewChildDiskBacking",
        pool         => $ticket_resource_pool
    );
    return $relocate_spec;
}

#tested
sub ConfigSpec {
    my ( $memory, $cpu, $os_temp ) = @_;
    &Log::debug(
"Starting Support::ConfigSpec sub, memory=>'$memory', cpu=>'$cpu', os_temp=>'$os_temp'"
    );
    my $config_spec = VirtualMachineConfigSpec->new(
        memoryMB     => $memory,
        numCPUs      => $cpu,
        deviceChange => [ &Guest::generate_network_setup($os_temp) ]
    );
    return $config_spec;
}

#tested
sub CustomizationPassword {
    &Log::debug("Starting Support::CustomizationPassword sub");
    return CustomizationPassword->new( plainText => 1, value => 'titkos' );
}

#tested
sub identification_domain {
    &Log::debug("Starting Support::identification_domain sub");
    return CustomizationIdentification->new(
        domainAdmin         => 'Administrator@support.balabit',
        domainAdminPassword => &CustomizationPassword,
        joinDomain          => 'support.balabit'
    );
}

#tested
sub identification_workgroup {
    &Log::debug("Starting Support::identification_workgroup sub");
    return CustomizationIdentification->new(
        domainAdmin         => 'Administrator@support.balabit',
        domainAdminPassword => &CustomizationPassword,
        joinWorkgroup       => 'SUPPORT'
    );
}

#tested
sub win_CloneSpec {
    my ( $os_temp, $snapshot_view, $relocate_spec, $config_spec, $domain, $key )
      = @_;
    &Log::debug(
"Starting Support::win_CloneSpec sub, os_temp=>'$os_temp', domain=>'$domain', key=>'$key'"
    );
    my @nicsetting = &Guest::CustomizationAdapterMapping_generator($os_temp);
    my $globalipsettings = CustomizationGlobalIPSettings->new(
        dnsServerList => ['10.10.0.1'],
        dnsSuffixList => ['support.balabit']
    );
    my $customoptions =
      CustomizationWinOptions->new( changeSID => 1, deleteAccounts => 0 );
    my $guiunattend = CustomizationGuiUnattended->new(
        autoLogon      => 1,
        autoLogonCount => 1,
        password       => &CustomizationPassword,
        timeZone       => '095'
    );
    my $customname = CustomizationPrefixName->new( base => 'winguest' );
    my $userdata = CustomizationUserData->new(
        productId    => $key,
        orgName      => 'support',
        fullName     => 'admin',
        computerName => $customname
    );
    my $identification;

    if ($domain) {
        $identification = &identification_domain;
    }
    else {
        $identification = &identification_workgroup;
    }
    my $runonce = CustomizationGuiRunOnce->new(
        commandList => [
            "w32tm /resync",
"cscript c:/windows/system32/slmgr.vbs /skms prod-dev-winsrv.balabit",
            "cscript c:/windows/system32/slmgr.vbs /ato"
        ]
    );
    my $identity;
    if ( $os_temp =~ /^T_win_200[03]/ ) {
        &Log::debug("Need to use the win2k3/2k license method");
        my $licenseprintdata =
          CustomizationLicenseFilePrintData->new(
            autoMode => CustomizationLicenseDataMode->new('perSeat') );
        $identity = CustomizationSysprep->new(
            guiRunOnce           => $runonce,
            guiUnattended        => $guiunattend,
            identification       => $identification,
            userData             => $userdata,
            licenseFilePrintData => $licenseprintdata
        );
    }
    else {
        $identity = CustomizationSysprep->new(
            guiRunOnce     => $runonce,
            guiUnattended  => $guiunattend,
            identification => $identification,
            userData       => $userdata
        );
    }
    my $customization_spec = CustomizationSpec->new(
        globalIPSettings => $globalipsettings,
        identity         => $identity,
        options          => $customoptions,
        nicSettingMap    => [@nicsetting]
    );
    my $clone_spec = VirtualMachineCloneSpec->new(
        powerOn       => 1,
        template      => 0,
        snapshot      => $snapshot_view,
        location      => $relocate_spec,
        config        => $config_spec,
        customization => $customization_spec
    );
    &Log::debug("Returning win Clone Spec");
    return $clone_spec;
}

#tested
sub lin_CloneSpec {
    my ( $os_temp, $snapshot_view, $relocate_spec, $config_spec ) = @_;
    &Log::debug("Starting Support::lin_CloneSpec sub, os_temp=>'$os_temp'");
    my @nicsetting = &Guest::CustomizationAdapterMapping_generator($os_temp);
    my $hostname = CustomizationPrefixName->new( base => 'linuxguest' );
    my $globalipsettings = CustomizationGlobalIPSettings->new(
        dnsServerList => ['10.10.0.1'],
        dnsSuffixList => ['support.balabit']
    );
    my $linuxprep = CustomizationLinuxPrep->new(
        domain     => 'support.balabit',
        hostName   => $hostname,
        timeZone   => 'Europe/Budapest',
        hwClockUTC => 1
    );
    my $customization_spec = CustomizationSpec->new(
        identity         => $linuxprep,
        globalIPSettings => $globalipsettings,
        nicSettingMap    => [@nicsetting]
    );
    my $clone_spec = VirtualMachineCloneSpec->new(
        powerOn       => 1,
        template      => 0,
        snapshot      => $snapshot_view,
        location      => $relocate_spec,
        config        => $config_spec,
        customization => $customization_spec
    );
    &Log::debug("Returning lin Clone Spec");
    return $clone_spec;
}

#tested
sub oth_CloneSpec {
    my ( $snapshot_view, $relocate_spec, $config_spec ) = @_;
    &Log::debug("Starting Support::oth_CloneSpec sub");
    my $clone_spec = VirtualMachineCloneSpec->new(
        powerOn  => 1,
        template => 0,
        snapshot => $snapshot_view,
        location => $relocate_spec,
        config   => $config_spec
    );
    &Log::debug("Returning oth Clone Spec");
    return $clone_spec;
}

__END__
