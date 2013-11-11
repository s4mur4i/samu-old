package Support;

use strict;
use warnings;

=pod

=head1 Support.pm

Subroutines from BB/Support.pm

=cut

BEGIN {
    use Exporter;
    our @ISA    = qw( Exporter );
    our @EXPORT = qw( );
}

my %template_hash = (
    'scb_300' => {
        path     => 'Support/vm/templates/SCB/scb_3.0/T_scb_300',
        username => 'root',
        password => 'titkos',
        os       => 'xcb'
    },
    'scb_330' => {
        path     => 'Support/vm/templates/SCB/scb_3.3/T_scb_330',
        username => 'root',
        password => 'titkos',
        os       => 'xcb'
    },
    'scb_341' => {
        path     => 'Support/vm/templates/SCB/scb_3.4/T_scb_341',
        username => 'root',
        password => 'titkos',
        os       => 'xcb'
    },
    'scb_342' => {
        path     => 'Support/vm/templates/SCB/scb_3.4/T_scb_342',
        username => 'root',
        password => 'titkos',
        os       => 'xcb'
    },
    'scb_350' => {
        path     => 'Support/vm/templates/SCB/scb_3.5/T_scb_350',
        username => 'root',
        password => 'default',
        os       => 'xcb'
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
    'win_7sp1_en_x64_ent' => {
        path     => 'Support/vm/templates/Windows/7/T_win_7sp1_en_x64_ent',
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
        password => 'titkos',
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
        password => 'titkos',
        key      => 'YC6KT-GKW9T-YTKYR-T4X34-R7VHC',
        os       => 'win'
    },
    'win_2008r2_en_x64_stadeb' => {
        path => 'Support/vm/templates/Windows/2008/T_win_2008r2_en_x64_stadeb',
        username => 'Administrator',
        password => 'titkos',
        key      => 'YC6KT-GKW9T-YTKYR-T4X34-R7VHC',
        os       => 'win'
    },
    'win_2008r2_en_x64_ent' => {
        path     => 'Support/vm/templates/Windows/2008/T_win_2008r2_en_x64_ent',
        username => 'Administrator',
        password => 'titkos',
        key      => '489J6-VHDMP-X63PK-3K798-CPX3Y',
        os       => 'win'
    },
    'win_2008r2sp1_en_x64_sta' => {
        path => 'Support/vm/templates/Windows/2008/T_win_2008r2sp1_en_x64_sta',
        username => 'Administrator',
        password => 'titkos',
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
#FIXME need to correct vmware tools
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
#FIXME add product key to be able to provision
    'win_8_en_x64_ent' => {
        path => 'Support/vm/templates/Windows/Win8/T_win_8_en_x64_ent',
        username => 'admin',
        password => 'titkos',
        os => 'win'
    },
);

my %agents_hash = (
    's4mur4i' => { mac => '02:01:20:', ip => '10.21.32.' },
    'balage'  => { mac => '02:01:12:' },
    'adrienn' => { mac => '02:01:40:' },
    'varnyu'  => { mac => '02:01:19:' },
    'kkovari' => { mac => '02:01:00:' },
    'szaki'   => { mac => '02:01:00:' },
    'blehel'  => { mac => '02:01:00:' },
    'imre'    => { mac => '02:01:00:' },
    'janos'   => { mac => '02:01:5F:', ip => '10.21.95.' },
);

my %map_hash = (
    'agents'   => \%agents_hash,
    'template' => \%template_hash,
);

=pod

=head2 get_keys

=head3 PURPOSE

Returns keys of hash

=head3 PARAMETERS

=over

=item hash

Name of hash

=back

=head3 RETURNS

Array ref with keys

=head3 DESCRIPTION

=head3 THROWS

Template::Status if no hash is found

=head3 COMMENTS

=head3 TEST COVERAGE

Tested if agents hash returns array
Tested if unknown map returns exception

=cut

sub get_keys {
    my ($hash) = @_;
    &Log::debug("Starting Support::get_keys sub");
    &Log::debug1("Opts are: hash=>'$hash'");
    if ( !defined( $map_hash{$hash} ) ) {
        Template::Status->throw(
            error    => 'Requested hash_map was not found',
            template => $hash
        );
    }
    my $req_hash = $map_hash{$hash};
    my $return   = [ keys %$req_hash ];
    &Log::debug("Finishing Support::get_keys sub");
    &Log::dumpobj( "req_hash", $return );
    return $return;
}

=pod

=head2 get_hash

=head3 PURPOSE

Returns hash with information

=head3 PARAMETERS

=over

=item hash

Name of hash to use

=item key

Key of hash to return

=back

=head3 RETURNS

Hash reference with information

=head3 DESCRIPTION

=head3 THROWS

Template::Status if no information is found

=head3 COMMENTS

=head3 TEST COVERAGE

Tested if exception is thrown for bad map or bad key

=cut

sub get_hash {
    my ( $hash, $key ) = @_;
    &Log::debug("Starting Support::get_hash sub");
    &Log::debug1("Opts are: hash=>'$hash', key=>'$key'");
    if ( !defined( $map_hash{$hash}->{$key} ) ) {
        Template::Status->throw(
            error    => 'Requested key info was not found',
            template => $key
        );
    }
    &Log::debug("Finishing Support::get_hash sub");
    &Log::dumpobj( "key_info", $map_hash{$hash}->{$key} );
    return $map_hash{$hash}->{$key};
}

=pod

=head2 get_key_value

=head3 PURPOSE

Returns a value from hash of hash

=head3 PARAMETERS

=over

=item hash

Which hash to use

=item key

What is the key of first hash

=item value

The key of hash of hash

=back

=head3 RETURNS

Value of hash of hash

=head3 DESCRIPTION

=head3 THROWS

Template::Status if no information found

=head3 COMMENTS

=head3 TEST COVERAGE

Tested if array is returned
Tested if exception is thrown for bad map, bad key or bad value key

=cut

sub get_key_value {
    my ( $hash, $key, $value ) = @_;
    &Log::debug("Starting Support::get_key_value sub");
    &Log::debug1("Opts are: hash=>'$hash', key=>'$key', value=>'$value'");
    my $key_hash = &Support::get_hash( $hash, $key );
    if ( !defined( $$key_hash{$value} ) ) {
        Template::Status->throw(
            error    => 'Requested key value was not found',
            template => $value
        );
    }
    &Log::debug("Finishing Support::get_key_value sub");
    &Log::debug( "Return=>'" . $$key_hash{$value} . "'" );
    return $$key_hash{$value};
}

=pod

=head2 RelocateSpec

=head3 PURPOSE

Returns a VirtualMachineRelocateSpec managed object for installation

=head3 PARAMETERS

=over

=item ticket

The ticket number

=back

=head3 RETURNS

VirtualMachineRelocateSpec managed object

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

=head3 TEST COVERAGE

Tested with all templates if valid object is returned

=cut

sub RelocateSpec {
    my ($ticket) = @_;
    &Log::debug("Starting Support::RelocateSpec sub");
    &Log::debug1("Opts are: ticket=>'$ticket'");
    my $host_view =
      &Guest::entity_name_view( 'vmware-it1.balabit', 'HostSystem' );
    my $ticket_resource_pool =
      &Guest::entity_name_view( $ticket, 'ResourcePool' );
    my $relocate_spec = VirtualMachineRelocateSpec->new(
        host         => $host_view,
        diskMoveType => "createNewChildDiskBacking",
        pool         => $ticket_resource_pool
    );
    &Log::debug("Finishing Support::RelocateSpec sub");
    &Log::dumpobj( "relocate_spec", $relocate_spec );
    return $relocate_spec;
}

=pod

=head2 ConfigSpec

=head3 PURPOSE

Generates VirtualMachineConfigSpec managed object for installation

=head3 PARAMETERS

=over

=item memory

Requested memory ammount

=item cpu

Number of cores to give to virtual machine

=item os_temp

The template that is being used to clone machine

=back

=head3 RETURNS

VirtualMachineConfigSpec Managd object

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

=head3 TEST COVERAGE

Tested with all templates if valid object is returned

=cut

sub ConfigSpec {
    my ( $memory, $cpu, $os_temp ) = @_;
    &Log::debug("Starting Support::ConfigSpec sub");
    &Log::debug1(
        "Opts are: memory=>'$memory', cpu=>'$cpu', os_temp=>'$os_temp'");
    my $config_spec = VirtualMachineConfigSpec->new(
        memoryMB     => $memory,
        numCPUs      => $cpu,
        deviceChange => [ &Guest::generate_network_setup($os_temp) ]
    );
    &Log::debug("Finishing Support::ConfigSpec sub");
    &Log::dumpobj( "config_spec", $config_spec );
    return $config_spec;
}

=pod

=head2 CustomizationPassword

=head3 PURPOSE

Returns a CustomizationPassword managed object for Standard password use

=head3 PARAMETERS

=over

=back

=head3 RETURNS

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

=head3 TEST COVERAGE

Tested with all templates if valid object is returned

=cut

sub CustomizationPassword {
    &Log::debug("Starting Support::CustomizationPassword sub");
    my $ret = CustomizationPassword->new( plainText => 1, value => 'titkos' );
    &Log::debug("Finishing Support::CustomizationPassword sub");
    &Log::dumpobj( "CustomizationPassword", $ret );
    return $ret;
}

=pod

=head2 identification_domain

=head3 PURPOSE

Returns CustomizationIdentification managed object for domain join

=head3 PARAMETERS

=over

=back

=head3 RETURNS

CustomizationIdentification managed object

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

=head3 TEST COVERAGE

Tested with all templates if valid object is returned

=cut

sub identification_domain {
    &Log::debug("Starting Support::identification_domain sub");
    my $ret = CustomizationIdentification->new(
        domainAdmin         => 'Administrator@support.balabit',
        domainAdminPassword => &CustomizationPassword,
        joinDomain          => 'support.balabit'
    );
    &Log::debug("Finishing Support::identification_domain sub");
    &Log::dumpobj( "CustomizationIdentification", $ret );
    return $ret;
}

=pod

=head2 identification_workgroup

=head3 PURPOSE

Returns a CustomizationIdetification managed object for workgroup join

=head3 PARAMETERS

=over

=back

=head3 RETURNS

CustomizationIdetification managed object

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

=head3 TEST COVERAGE

Tested with all templates if valid object is returned

=cut

sub identification_workgroup {
    &Log::debug("Starting Support::identification_workgroup sub");
    my $ret = CustomizationIdentification->new(
        domainAdmin         => 'Administrator@support.balabit',
        domainAdminPassword => &CustomizationPassword,
        joinWorkgroup       => 'SUPPORT'
    );
    &Log::debug("Finishing Support::idetification_workgroup sub");
    &Log::dumpobj( "CustomizationIdetification", $ret );
    return $ret;
}

=pod

=head2 win_CloneSpec

=head3 PURPOSE

Returns a Clonespec for cloneing

=head3 PARAMETERS

=over

=item os_temp

The template the Linux virtual machine is going to be attached

=item snapshot_view

Snapshot Managed object to attach clone to

=item relocate_spec

Destination for created clone

=item config_spec

Config spec for creation of Virtual Machine

=back

=head3 RETURNS

A VirtualMachineCloneSpec managed object

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

=head3 TEST COVERAGE

Tested with all templates if valid object is returned

=cut

sub win_CloneSpec {
    my ( $os_temp, $snapshot_view, $relocate_spec, $config_spec, $domain, $key )
      = @_;
    &Log::debug("Starting Support::win_CloneSpec sub");
    &Log::debug(
        "Opts are: os_temp=>'$os_temp', domain=>'$domain', key=>'$key'");
    my @nicsetting =
      @{ &Guest::CustomizationAdapterMapping_generator($os_temp) };
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
    &Log::dumpobj( "clone_spec", $clone_spec );
    &Log::debug("Finishing Misc::win_CloneSpec sub");
    return $clone_spec;
}

=pod

=head2 lin_CloneSpec

=head3 PURPOSE

Returns a Clonespec for cloneing

=head3 PARAMETERS

=over

=item os_temp

The template the Linux virtual machine is going to be attached

=item snapshot_view

Snapshot Managed object to attach clone to

=item relocate_spec

Destination for created clone

=item config_spec

Config spec for creation of Virtual Machine

=back

=head3 RETURNS

A VirtualMachineCloneSpec managed object

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

=head3 TEST COVERAGE

Tested with all templates if valid object is returned

=cut

sub lin_CloneSpec {
    my ( $os_temp, $snapshot_view, $relocate_spec, $config_spec ) = @_;
    &Log::debug("Starting Support::lin_CloneSpec sub");
    &Log::debug1("Opts are: os_temp=>'$os_temp'");
    my @nicsetting =
      @{ &Guest::CustomizationAdapterMapping_generator($os_temp) };
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
    &Log::dumpobj( "clone_spec", $clone_spec );
    &Log::debug("Finishing Support::lin_CloneSpec sub");
    return $clone_spec;
}

=pod

=head2 oth_CloneSpec

=head3 PURPOSE

Returns a Clonespec for cloneing

=head3 PARAMETERS

=over

=item snapshot_view

Snapshot Managed object to attach clone to

=item relocate_spec

Destination for created clone

=item config_spec

Config spec for creation of Virtual Machine

=back

=head3 RETURNS

A VirtualMachineCloneSpec managed object

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

=head3 TEST COVERAGE

Tested with all templates if valid object is returned

=cut

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
    &Log::dumpobj( "clone_spec", $clone_spec );
    &Log::debug("Finishing Support::oth_CloneSpec sub");
    return $clone_spec;
}

1
