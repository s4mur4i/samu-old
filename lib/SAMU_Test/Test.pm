package Test;

use strict;
use warnings;
use FindBin;
use Module::Load;
use Test::More;
use Data::Dumper;

my $pod_hash = {};
my $autocomplete = {};

=pod

=head1 Test.pm

Subroutines for SAMU_Test/Test.pm

=cut

BEGIN {
    use Exporter;
    our @ISA    = qw( Exporter );
    our @EXPORT = qw( );
}

sub clonevm {
    my ( $template, $vmname, $folder, $clone_spec ) = @_;
    my $template_view = &Guest::entity_name_view( $template, 'VirtualMachine' );
    my $folder_view   = &Guest::entity_name_view( $folder,   'Folder' );
    my $task          = $template_view->CloneVM_Task(
        folder => $folder_view,
        name   => $vmname,
        spec   => $clone_spec
    );
    &VCenter::Task_Status($task);
    return 1;
}

sub create_test_vm {
    my ($name) = @_;
    &Log::debug("Starting Test::create_test_vm");
    &VCenter::num_check( 'test_1337', 'ResourcePool' );
    my $resource_pool = &Guest::entity_name_view( 'test_1337', 'ResourcePool' );
    &VCenter::num_check( 'test_1337', 'Folder' );
    my $folder = &Guest::entity_name_view( 'test_1337', 'Folder' );
    &VCenter::num_check( 'test_1337', 'DistributedVirtualSwitch' );
    my $host_view =
      &Guest::entity_name_view( 'vmware-it1.balabit', 'HostSystem' );
    my $network_list = Vim::get_views( mo_ref_array => $host_view->network );
    my @vm_devices;
    my $files = VirtualMachineFileInfo->new(
        logDirectory      => undef,
        snapshotDirectory => undef,
        suspendDirectory  => undef,
        vmPathName        => '[support] test_1337'
    );

    foreach (@$network_list) {
        if ( $_->name =~ /^test_1337_dvg/ ) {
            my $network          = $_;
            my $nic_backing_info = VirtualEthernetCardNetworkBackingInfo->new(
                deviceName    => 'test_1337_dvg',
                useAutoDetect => 1,
                network       => $network
            );
            my $vd_connect_info = VirtualDeviceConnectInfo->new(
                allowGuestControl => 1,
                connected         => 0,
                startConnected    => 1
            );
            my $nic = VirtualPCNet32->new(
                backing     => $nic_backing_info,
                key         => 0,
                addressType => 'generated',
                connectable => $vd_connect_info
            );
            my $nic_vm_dev_conf_spec = VirtualDeviceConfigSpec->new(
                device    => $nic,
                operation => VirtualDeviceConfigSpecOperation->new('add')
            );
            push( @vm_devices, $nic_vm_dev_conf_spec );
        }
    }
    my $config_spec = VirtualMachineConfigSpec->new(
        name         => $name,
        memoryMB     => '512',
        files        => $files,
        numCPUs      => 1,
        guestId      => 'winNetEnterpriseGuest',
        deviceChange => \@vm_devices
    );
    $folder->CreateVM( pool => $resource_pool, config => $config_spec );
    return 1;
}

sub create_test_entities {
    &VCenter::create_resource_pool( 'test_1337', 'Resources' );
    &VCenter::create_folder( 'test_1337', 'vm' );
    &VCenter::create_switch('test_1337');
    return 1;
}

sub uniq {
    return keys %{ { map { $_ => 1 } @_ } };
}

sub search_file {
    my ( $file, $string ) = @_;
    open( my $fh, "<", $file ) or die $!;
    while ( my $line = <$fh> ) {
        if ( $line =~ /'$string'/ ) {
            return 1;
        }
    }
    return 0;
}

sub module_namespace {
    my $libdir;
    if ( -d "$FindBin::Bin/../lib" ) {
        $libdir = "$FindBin::Bin/../lib";
    }
    else {
        $libdir = "$FindBin::Bin/../../lib";
    }
    opendir( my $dir, $libdir );
    my @folder = grep { $_ ne '.' && $_ ne '..' } readdir $dir;
    closedir $dir;
    return \@folder;
}

sub traverse_opts {
    my ( $opts, $path, $doc_path ) = @_;
    if ( exists $opts->{helper} ) {
        &Test::find_in_pod( $opts->{helper}, $doc_path );
    }
    if ( scalar(%$autocomplete) eq 0 ) {
        &Test::parse_autocomplete("$FindBin::Bin/../../bash_completion/samu");
    }
    if ( exists $opts->{module} ) {
        my $module = 'Base::' . $opts->{module};
        eval { load $module; };
        my $ret = 0;
        if ($@) {
            $ret = 1;
        }
        is( $ret, 0, "$module loaded successfully" );
    }
    if ( exists $opts->{prereq_module} ) {
        for my $module ( @{ $opts->{prereq_module} } ) {
            eval { load $module; };
            my $ret = 0;
            if ($@) {
                $ret = 1;
            }
            is( $ret, 0, "$module loaded successfully" );
        }
    }
    if ( exists $opts->{function}) {
        #diag(Dumper $opts);
        #diag(Dumper $path);
        my $func_ret = 0;
        my $podname = join( "_", @$path ) . "_function";
        if ( defined &{ $opts->{function} } ) {
            $func_ret = 1;
        }
        is( $func_ret, 1, "$$path[-1] can be invoked" );
        is( exists( $opts->{opts} ) // 0, 1, "$$path[-1] opts exists" );
        my $compname = lc( join( "_", @$path ));
        for my $key ( keys $opts->{opts} ) {
            &Test::find_in_pod( "$$path[0]_functions/$podname/OPTIONS/item/$key", $doc_path );
            is( defined($opts->{opts}->{$key}->{type}),1,"$key has type defined");
            is( defined($opts->{opts}->{$key}->{help}),1,"$key has help defined");
            is( defined($opts->{opts}->{$key}->{required}),1,"$key has required defined");
            is( defined($opts->{opts}->{$key}->{default}),1,"$key has default defined");
            is( defined($autocomplete->{$compname}->{$key}),1,"$compname has $key opt");
            $autocomplete->{$compname}->{$key} = 0;
        }
        my $items = &Test::return_pod_hash( "$$path[0]_functions/$podname/OPTIONS/item", $doc_path);
        for my $item (keys %$items) {
            is( defined($opts->{opts}->{$item}), 1, "$item is defined in module opts");
        }
        &Test::find_in_pod( "$$path[0]_functions/$podname/SYNOPSIS", $doc_path );
        is( exists( $opts->{vcenter_connect} ) // 0, 1, "Vcenter_connect exists" );
        if ( $opts->{vcenter_connect} ) {
            is( $autocomplete->{$compname}->{OPTS}->{sdk_opts}, 1, "_ part of options in autocomplete has sdk_opts");
            delete( $autocomplete->{$compname}->{OPTS}->{sdk_opts});
        }
        &Test::find_in_pod( "$$path[0]_functions/$podname", $doc_path );
        is(exists($opts->{helper}), '', "Function has no helper defined" );
    }
    if ( exists $opts->{functions} ) {
        for my $key ( keys $opts->{functions} ) {
            is(defined($opts->{helper}), 1, "Functions has helper defined" );
            if ( scalar(@$path) gt 1 ) {
                my $podname = join( "_", @$path ) . "_function";
                my $compname = lc( join( "_", @$path ));
                &Test::find_in_pod( "$$path[0]_functions/$podname", $doc_path );
                is( defined($autocomplete->{$compname}->{$key}),1,"$compname has $key opt");
                $autocomplete->{$compname}->{$key} = 0;
            }
            push( @$path, $key );
            &Test::traverse_opts( $opts->{functions}->{$key}, $path );
        }
    }
    pop(@$path);
}

sub parse_autocomplete {
    my ( $file ) = @_;
    open ( my $fh, "<", $file) or die "Could not open completion file";
    while ( my $line = <$fh>) {
        if ( $line =~ /^\s*([^_ ][^=]*)="([^"]*)"\s$/ ) {
            if ( $1 =~ /sdk_opts|cur_opt|default_opts|opt_var|cur|helper_opts|local varname/) {
                next;
            }
            my $val = $1;
            $autocomplete->{$val} = {};
            for my $element ( split(" ", $2) ) {
                if ( $element =~ /^\s*-{1,2}(.*)\s*$/) {
                    $element = $1;
                }
                $autocomplete->{$val}->{$element} = 1;
            }
        } elsif ( $line =~ /^\s*_([^ =]*)_options="([^"]*)"\s$/) {
            my $val = $1;
            $autocomplete->{$val}->{OPTIONS} = 1;
            for my $opt ( split(" ",$2) ) {
                if ( $opt =~ /^\${([^}]*)}$/) {
                    $opt = $1;
                }
                if ( !defined($autocomplete->{$val}->{OPTS}) ) {
                    $autocomplete->{$val}->{OPTS} ={};
                }
                $autocomplete->{$val}->{OPTS}->{$opt} = 1;
            }
        }
    }
    #use Data::Dumper;
    #diag(Dumper $autocomplete);
    close $fh;
}

sub parse_pod {
    my ($file) = @_;
    open( my $fh, "<", $file ) or die "Could not open file";
    my @path;
    while ( my $line = <$fh> ) {
        if ( $line =~ /^=head1\s(.*)\s*$/ ) {
            $pod_hash->{$1} = {};
            @path = ($1);
        }
        if ( $line =~ /^=head2\s(.*)\s*$/ ) {
            while ( scalar(@path) gt 1 ) {
                pop @path;
            }
            push( @path, $1 );
            $pod_hash->{ $path[0] }->{$1} = {};
        }
        if ( $line =~ /^=head3\s(.*)\s*$/ ) {
            while ( scalar(@path) gt 2 ) {
                pop @path;
            }
            push( @path, $1 );
            $pod_hash->{ $path[0] }->{ $path[1] }->{$1} = {};

        }
        if ( $line =~ /^=head4\s(.*)\s$/ ) {
            while ( scalar(@path) gt 3 ) {
                pop @path;
            }
            push( @path, $1 );
            $pod_hash->{ $path[0] }->{ $path[1] }->{ $path[2] }->{$1} = {};
        }
        if ( $line =~ /^=over\s*$/ ) {
            if ( scalar(@path) eq 1 ) {
                $pod_hash->{ $path[0] }->{item} = {};
            }
            elsif ( scalar(@path) eq 2 ) {
                $pod_hash->{ $path[0] }->{ $path[1] }->{item} = {};
            }
            elsif ( scalar(@path) eq 3 ) {
                $pod_hash->{ $path[0] }->{ $path[1] }->{ $path[2] }->{item} =
                  {};
            }
            elsif ( scalar(@path) eq 4 ) {
                $pod_hash->{ $path[0] }->{ $path[1] }->{ $path[2] }
                  ->{ $path[3] }->{item} = {};
            }
        }
        if ( $line =~ /^=item\s*(.*)\s*$/ ) {
            if ( scalar(@path) eq 1 ) {
                $pod_hash->{ $path[0] }->{item}->{$1} = 1;
            }
            elsif ( scalar(@path) eq 2 ) {
                $pod_hash->{ $path[0] }->{ $path[1] }->{item}->{$1} = 1;
            }
            elsif ( scalar(@path) eq 3 ) {
                $pod_hash->{ $path[0] }->{ $path[1] }->{ $path[2] }->{item}
                  ->{$1} = 1;
            }
            elsif ( scalar(@path) eq 4 ) {
                $pod_hash->{ $path[0] }->{ $path[1] }->{ $path[2] }
                  ->{ $path[3] }->{item}->{$1} = 1;
            }
        }
    }
    close $fh;
}

sub find_in_pod {
    my ( $path, $doc_path ) = @_;
    #diag("path=>'$path'");
    my @helper = split( "/", $path );
    if ( scalar(%$pod_hash) eq 0 ) {
        &Test::parse_pod($doc_path);
    }
    is( exists( $pod_hash->{ $helper[0] } ), 1, "$helper[0] is in pod" );
    if ( scalar(@helper) eq 2 ) {
        is( exists( $pod_hash->{ $helper[0] }->{ $helper[1] } ),
            1, "$helper[1] is in pod" );
    }
    elsif ( scalar(@helper) eq 3 ) {
        is( exists( $pod_hash->{ $helper[0] }->{ $helper[1] } ), 1, "$helper[1] is in pod" );
        is( exists( $pod_hash->{ $helper[0] }->{ $helper[1] }->{ $helper[2] } ), 1, "$helper[2] is in pod");
    }
    elsif ( scalar(@helper) eq 4 ) {
        is( exists( $pod_hash->{ $helper[0] }->{ $helper[1] } ), 1, "$helper[1] is in pod" );
        is( exists( $pod_hash->{ $helper[0] }->{ $helper[1] }->{ $helper[2] } ), 1, "$helper[2] is in pod");
        is( exists( $pod_hash->{ $helper[0] }->{ $helper[1] }->{ $helper[2] } ->{ $helper[3] }), 1, "$helper[3] is in pod");
    }
    elsif ( scalar(@helper) eq 5 ) {
        is( exists( $pod_hash->{ $helper[0] }->{ $helper[1] } ), 1, "$helper[1] is in pod" );
        is( exists( $pod_hash->{ $helper[0] }->{ $helper[1] }->{ $helper[2] } ), 1, "$helper[2] is in pod");
        is( exists( $pod_hash->{ $helper[0] }->{ $helper[1]}->{ $helper[2] } ->{ $helper[3] }), 1, "$helper[3] is in pod");
        is( exists( $pod_hash->{ $helper[0] }->{ $helper[1]}->{ $helper[2] } ->{ $helper[3] }->{ $helper[4] }), 1, "$helper[4] is in pod");
    }
}

sub return_pod_hash {
    my ( $path, $doc_path ) = @_;
    my @helper = split( "/", $path );
    if ( scalar(%$pod_hash) eq 0 ) {
        &Test::parse_pod($doc_path);
    }
    my $ret;
    if ( scalar(@helper) eq 0 ) {
        die "ERROR";
    } elsif ( scalar(@helper) eq 1) {
        return $pod_hash->{$helper[0]};
    } elsif( scalar(@helper) eq 2) {
        return $pod_hash->{$helper[0]}->{$helper[1]};
    } elsif( scalar(@helper) eq 3) {
        return $pod_hash->{$helper[0]}->{$helper[1]}->{$helper[2]};
    } elsif( scalar(@helper) eq 4) {
        return $pod_hash->{$helper[0]}->{$helper[1]}->{$helper[2]}->{$helper[3]};
    } elsif( scalar(@helper) eq 5) {
        return $pod_hash->{$helper[0]}->{$helper[1]}->{$helper[2]}->{$helper[3]}->{$helper[4]};
    } elsif( scalar(@helper) eq 6) {
        return $pod_hash->{$helper[0]}->{$helper[1]}->{$helper[2]}->{$helper[3]}->{$helper[4]}->{$helper[5]};
    }
    die "There was no match, die";
}

sub verify_complete {
    my ( $module ) = @_;
    $module = lc($module);
    for my $key ( keys %$autocomplete) {
        if( $key =~ /^$module$/ ) {
            is( $autocomplete->{$key}->{OPTIONS}, 1, "$key has options defined in bash autocompletion");
            delete $autocomplete->{$key}->{OPTIONS};
            is( defined($autocomplete->{$key}->{OPTS}->{$key}), 1, "$key _ part of options in autocomplete has itself");
            is( scalar(keys $autocomplete->{$key}->{OPTS}), 1,"$key _ part has 1 element in autocomplete");
            delete($autocomplete->{$key}->{OPTS});
            for my $item ( keys $autocomplete->{$key}) {
                is(defined($autocomplete->{"${module}_$item"}), 1,"$module has $item defined");
            }
            next;
        }
        if ( $key !~ /^${module}_/) {
            next;
        }
        is( $autocomplete->{$key}->{OPTIONS}, 1, "$key has options defined in bash autocompletion");
        $autocomplete->{$key}->{OPTIONS} = 0;
        is( defined($autocomplete->{$key}->{OPTS}->{$key}), 1, "$key _ part of options in autocomplete has itself");
        is( scalar(keys $autocomplete->{$key}->{OPTS}), 1,"$key _ part has 1 element in autocomplete");
        $autocomplete->{$key}->{OPTS} = 0;
        delete($autocomplete->{$key}->{OPTIONS});
        delete($autocomplete->{$key}->{OPTS});
        for my $elem ( keys $autocomplete->{$key}) {
            is( $autocomplete->{$key}->{$elem},0,"$elem in $key is tested in autocomplete");
        }
    }
    #diag( Dumper $autocomplete);
}

1
