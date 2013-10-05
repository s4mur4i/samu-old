package entity;

use strict;
use warnings;
use Base::misc;
use Data::Dumper;

my $help = 0;

BEGIN {
    use Exporter();
    our ( @ISA, @EXPORT );

    @ISA    = qw(Exporter);
    @EXPORT = qw(&main);
}

### subs

=pod

=head1 ENTITY_MAIN

=head2 DESCRIPTION

    This is the main entry sub to the vm (entity) functions. All further functions can be reached from here

=cut

our $module_opts = {
    helper    => 'VM',
    functions => {
        clone => {
            function => \&clone_vm,
            opts     => {
                ticket => {
                    type => "=s",
                    help =>
                      "The ticket id the machine is going to be created for",
                    required => 1,
                },
                os_temp => {
                    type     => "=s",
                    help     => "The machine tempalte we want to use",
                    required => 1,
                },
                parent_pool => {
                    type     => "=s",
                    help     => "Parent resource pool. Defaults to users pool.",
                    default  => 'Resources',
                    required => 0,
                },
                memory => {
                    type     => "=s",
                    help     => "Requested memory in MB",
                    required => 0,
                },
                cpu => {
                    type     => "=s",
                    help     => "Requested Core count for machine",
                    required => 0,
                },
                domain => {
                    type => "",
                    help =>
"Should the requested machine be added to support.ittest.domain",
                    default  => 0,
                    required => 0,
                },
            },
        },
        convert_full => {
            function => \&promote,
            opts => {
                vmname => {
                    type => "=s",
                    help => "Which machine to convert",
                    required => 1,
                },
            },
        },
        info => {
            helper    => 'VM_functions/VM_info_function',
            functions => {
                dumper => {
                    function => \&info_dumper,
                    opts     => {
                        vmname => {
                            type => "=s",
                            help =>
                              "The vm's name which information should be dump",
                            required => 1,
                        },
                    },
                },
                runtime => {
                    function => \&info_runtime,
                    opts     => {
                        vmname => {
                            type => "=s",
                            help =>
                              "The vm's name which information should be dump",
                            required => 1,
                        },
                    }
                },
            },
        },
        add => {
            helper    => 'VM_functions/VM_add_function',
            functions => {
                cdrom => {
                    function => \&add_cdrom,
                    opts     => {
                        vmname => {
                            type => "=s",
                            help => "The vm's name where cdrom should be added",
                            required => 1,
                        },
                    },
                },
                interface => {
                    function => \&add_interface,
                    opts     => {
                        vmname => {
                            type => "=s",
                            help =>
                              "The vm's name where interface should be added",
                            required => 1,
                        },
                        type => {
                            type => "=s",
                            help =>
                              "Requested type of interface: E1000, Vmxnet",
                            required => 0,
                            default  => "E1000",
                        },
                    },
                },
                disk => {
                    function => \&add_disk,
                    opts     => {
                        vmname => {
                            type => "=s",
                            help => "The vm's name where disk should be added",
                            required => 1,
                        },
                        size => {
                            type     => "=s",
                            help     => "The size of the disk",
                            required => 1,
                        },
                    },
                },
                snapshot => {
                    function => \&add_snapshot,
                    opts     => {
                        vmname => {
                            type => "=s",
                            help =>
                              "The vm's name where snapshot should be created",
                            required => 1,
                        },
                        snap_name => {
                            type     => "=s",
                            help     => "Snapshots name",
                            default  => "snap",
                            required => 0,
                        },
                        desc => {
                            type     => "=s",
                            help     => "The snapshots description",
                            default  => "I am a snapshot",
                            required => 0,
                        },
                    },
                },
                folder => {
                    function => \&add_folder,
                    opts => {
                        name => {
                            type     => "=s",
                            help     => "Name of folder to create",
                            required => 1,
                        },
                        parent => {
                            type     => "=s",
                            help     => "Name of parent to create in",
                            required => 0,
                            default => "vm",
                        },
                    },
                },
                resourcepool => {
                    function => \&add_resourcepool,
                    opts => {
                        name => {
                            type     => "=s",
                            help     => "Name of folder to create",
                            required => 1,
                        },
                        parent => {
                            type     => "=s",
                            help     => "Name of parent to create in",
                            required => 0,
                            default => "resources",
                        },
                    },
                },
            },
        },
        delete => {
            helper    => 'VM_functions/VM_delete_function',
            functions => {
                cdrom => {
                    function => \&delete_cdrom,
                    opts     => {
                        vmname => {
                            type     => '=s',
                            help     => 'Which VMs cdrom to list.',
                            required => '1',
                        },
                        id => {
                            type     => '=s',
                            help     => 'Which device to delete',
                            required => '1',
                        },
                    },
                },
                interface => {
                    function => \&delete_interface,
                    opts     => {
                        vmname => {
                            type     => '=s',
                            help     => 'Which VMs cdrom to list.',
                            required => '1',
                        },
                        id => {
                            type     => '=s',
                            help     => 'Which device to delete',
                            required => '1',
                        },
                    },
                },
                disk => {
                    function => \&delete_disk,
                    opts     => {
                        vmname => {
                            type     => '=s',
                            help     => 'Which VMs cdrom to list.',
                            required => '1',
                        },
                        id => {
                            type     => '=s',
                            help     => 'Which device to delete',
                            required => '1',
                        },
                    },
                },
                snapshot => {
                    function => \&delete_snapshot,
                    opts     => {
                        vmname => {
                            type     => '=s',
                            help     => 'Which VMs snapshot to delete',
                            required => '1',
                        },
                        id => {
                            type     => '=s',
                            help     => 'Id of snapshot to delete',
                            required => '0',
                        },
                        all => {
                            type     => '',
                            help     => 'Delete all snapshots',
                            required => '0',
                            default  => 0,
                        },
                    },
                },
                vm => {
                    function => \&delete_vm,
                    opts     => {
                        vmname => {
                            type     => '=s',
                            help     => "Name of vm to delete",
                            required => 1,
                        },
                    },
                },
                resourcepool => {
                    function => \&delete_resourcepool,
                    opts => {
                        name => {
                            type     => '=s',
                            help     => "Name of resource pool to delete",
                            required => 1,
                        },
                    },
                },
                folder => {
                    function => \&delete_folder,
                    opts => {
                        name => {
                            type     => '=s',
                            help     => "Name of folder to delete",
                            required => 1,
                        },
                    },
                },
            },
        },
        list => {
            helper    => 'VM_functions/VM_list_function',
            functions => {
                cdrom => {
                    function => \&list_cdrom,
                    opts     => {
                        vmname => {
                            type     => '=s',
                            help     => 'Which VMs cdrom to list.',
                            required => '1',
                        },
                    },
                },
                interface => {
                    function => \&list_interface,
                    opts     => {
                        vmname => {
                            type     => '=s',
                            help     => 'Which VMs interface to list.',
                            required => '1',
                        },
                    },
                },
                disk => {
                    function => \&list_disk,
                    opts     => {
                        vmname => {
                            type     => '=s',
                            help     => 'Which VMs disk to list.',
                            required => '1',
                        },
                    },
                },
                snapshot => {
                    function => \&list_snapshot,
                    opts     => {
                        vmname => {
                            type     => '=s',
                            help     => 'Name of vm to list snapshot',
                            required => 1,
                        },
                    },
                },
            },
        },
        change => {
            helper    => 'VM_functions/VM_change_function',
            functions => {
                cdrom => {
                    function => \&change_cdrom,
                    opts     => {
                        vmname => {
                            type     => '=s',
                            help     => 'Which VMs disk to list',
                            required => '1',
                        },
                        num => {
                            type     => '=s',
                            help     => 'Which cdrom to change',
                            required => '1',
                        },
                        iso => {
                            type     => '=s',
                            help     => 'Which iso to add',
                            required => '0',
                        },
                        unmount => {
                            type     => '',
                            help     => 'Unmount and iso',
                            required => '0',
                        },
                    },
                },
                interface => {
                    function => \&change_interface,
                    opts     => {
                        vmname => {
                            type     => '=s',
                            help     => 'Which VMs cdrom to list.',
                            required => '1',
                        },
                        num => {
                            type     => '=s',
                            help     => 'Which interface to manage',
                            required => '1',
                        },
                        network => {
                            type     => '=s',
                            help     => 'Which network to change to',
                            required => '0',
                            default => 'VLAN21',
                        },
                    },
                },
                disk => {
                    function => \&change_disk,
                    opts     => {
                        vmname => {
                            type     => '=s',
                            help     => 'Which VMs cdrom to list.',
                            required => '1',
                        },
                    },
                },
                altername => {
                    function => \&change_altername,
                    opts     => {
                        vmname => {
                            type     => '=s',
                            help     => 'Name of vm',
                            required => 1,
                        },
                        name => {
                            type     => '=s',
                            help     => 'Name of new alternate name for vm',
                            required => 1,
                        },
                    },
                },
                snapshot => {
                    function => \&change_snapshot,
                    opts     => {
                        vmname => {
                            type     => '=s',
                            help     => 'Name of vm',
                            required => 1,
                        },
                        id => {
                            type     => '=s',
                            help     => 'ID of snapshot to revert to',
                            required => 1,
                        },
                    },
                },
                power => {
                    function => \&change_power,
                    opts     => {
                        vmname => {
                            type     => '=s',
                            help     => 'Which VMs cdrom to list.',
                            required => '1',
                        },
                        state => {
                            type => '=s',
                            help =>
'What state should the vm be put in. Possible: on/off',
                            required => '1',
                        },
                    },
                },
            },
        },
        run => {
            prereq_module => [ qw(LWP::UserAgent)],
            function      => \&run_command,
            opts          => {
                vmname => {
                    type     => '=s',
                    help     => 'Which VMs should be used for running command',
                    required => '1',
                },
                guestusername => {
                    type     => "=s",
                    help     => "Custom username for guest OS",
                    required => 0,
                },
                guestpassword => {
                    type     => "=s",
                    help     => "Custom password for guest OS",
                    required => 0,
                },
                prog => {
                    type     => "=s",
                    help     => "Full path for program to run",
                    required => 1,
                },
                prog_arg => {
                    type     => "=s",
                    help     => "Arguments to program",
                    required => 1,
                },
                workdir => {
                    type     => "=s",
                    help     => "Working directory to run program in",
                    required => 1,
                },
                env => {
                    type     => "=s",
                    help     => "ENV settings for program",
                    required => 0,
                    default  => "",
                },
            },
        },
        transfer => {
            function => \&transfer,
            prereq_module => [ qw(LWP::Simple HTTP::Request LWP::UserAgent) ],
            opts     => {
                type => {
                    type     => '=s',
                    help     => 'Diretion of transfer, Values: to/from',
                    required => 1,
                },
                vmname => {
                    type     => '=s',
                    help     => 'Which VMs should be used for transfer',
                    required => '1',
                },
                guestusername => {
                    type     => "=s",
                    help     => "Custom username for guest OS",
                    required => 0,
                },
                guestpassword => {
                    type     => "=s",
                    help     => "Custom password for guest OS",
                    required => 0,
                },
                source => {
                    type     => "=s",
                    help     => "Source of file",
                    required => 1,
                },
                dest => {
                    type     => "=s",
                    help     => "Destination of file",
                    required => 1,
                },
                overwrite => {
                    type     => "=s",
                    help     => "Should files be overwritten during transfer",
                    required => 0,
                    default  => 0,
                },
            },
        },
    },
};

sub main {
    &Log::debug("Entity::main sub started");
    &misc::option_parser( $module_opts, "main" );
}

#tested
sub list_cdrom {
    &Log::debug("Entity::list_cdrom sub started");
    my $vmname = Opts::get_option('vmname');
    &Log::debug("Requested options, vmname=>'$vmname'");
    my @cdrom_hw = @{ &Guest::get_hw( $vmname, 'VirtualCdrom' ) };
    if ( @cdrom_hw eq 0 ) {
        &Log::debug("No cdroms on entity");
        print "Currently no cdroms attached to machine\n";
    }
    for ( my $i = 0 ; $i < scalar(@cdrom_hw) ; $i++ ) {
        &Log::debug("Iterating thorugh CDrom hardware '$i'");
        &Log::dumpobj( "cdrom $i", $cdrom_hw[$i] );
        my $backing = "Unknown";
        if ( $cdrom_hw[$i]->{backing}->isa('VirtualCdromIsoBackingInfo') ) {
            &Log::debug("Backing is a file backing");
            $backing = $cdrom_hw[$i]->{backing}->fileName;
        }
        elsif ( $cdrom_hw[$i]->{backing}
            ->isa('VirtualCdromRemotePassthroughBackingInfo')
            or
            $cdrom_hw[$i]->{backing}->isa('VirtualCdromRemoteAtapiBackingInfo')
          )
        {
            &Log::debug(
"Backing is a Client device backing either passthrough or emulated ide"
            );
            $backing = "Client Device";
        }
        elsif ( $cdrom_hw[$i]->{backing}->isa('VirtualCdromAtapiBackingInfo') )
        {
            &Log::debug("Backing is a Host device backing");
            $backing = $cdrom_hw[$i]->{backing}->{deviceName};
        }
        my $label = $cdrom_hw[$i]->{deviceInfo}->{label} || "None";
        print "number=>'"
          . $i
          . "', key=>'"
          . $cdrom_hw[$i]->{key}
          . "', backing=>'"
          . $backing
          . "', label=>'"
          . $label . "'\n";
    }
    &Log::debug("Finished list_cdrom sub");
    return 1;
}

#tested
sub list_interface {
    &Log::debug("Entity::list_interface sub started");
    my $vmname = Opts::get_option('vmname');
    &Log::debug("Requested options, vmname=>'$vmname'");
    my @net_hw = @{ &Guest::get_hw( $vmname, 'VirtualEthernetCard' ) };
    for ( my $i = 0 ; $i < scalar(@net_hw) ; $i++ ) {
        &Log::debug("Iterating thorugh Network hardware '$i'");
        &Log::dumpobj( "interface $i", $net_hw[$i] );
        my $type = "Unknown";
        if ( $net_hw[$i]->isa('VirtualE1000') ) {
            $type = "E1000";
        }
        else {
            &Log::debug(
                "Some unknown interface type, need to implement object handle");
        }
        print "number=>'$i', key=>'"
          . $net_hw[$i]->{key}
          . "', mac=>'"
          . $net_hw[$i]->{macAddress}
          . "', interface=>'"
          . $net_hw[$i]->{backing}->{deviceName}
          . "', type=>'"
          . $type
          . "', label=>'"
          . $net_hw[$i]->{deviceInfo}->{label} . "'\n";
    }
    return 1;
}

#tested
sub list_disk {
    &Log::debug("Entity::list_disk sub started");
    my $vmname = Opts::get_option('vmname');
    &Log::debug("Requested options, vmname=>'$vmname'");
    my @disk_hw = @{ &Guest::get_hw( $vmname, 'VirtualDisk' ) };
    &Log::dumpobj( "disk_hw", \@disk_hw );
    for ( my $i = 0 ; $i < scalar(@disk_hw) ; $i++ ) {
        &Log::debug("Iterating thorugh disk hardware '$i'");
        &Log::dumpobj( "disk $i", $disk_hw[$i] );
        print "number=>'"
          . $i
          . "', key=>'"
          . $disk_hw[$i]->{key}
          . "', size=>'"
          . $disk_hw[$i]->{capacityInKB}
          . "' KB, path=>'"
          . $disk_hw[$i]->{backing}->{fileName} . "'\n";
    }
    &Log::debug("Finished list_disk sub");
    return 1;
}

#tested
sub list_snapshot {
    &Log::debug("Entity::list_snapshot sub started");
    my $vmname = Opts::get_option('vmname');
    &Log::debug("Requested options, vmname=>'$vmname'");
    &Guest::list_snapshot($vmname);
    return 1;
}

#tested
sub change_altername {
    &Log::debug("Entity::change_altername sub started");
    my $vmname = Opts::get_option('vmname');
    my $name   = Opts::get_option('name');
    &Log::debug("Requested options, vmname=>'$vmname', name=>'$name'");
    &Guest::change_altername( $vmname, $name );
    return 1;
}

sub change_cdrom {
    &Log::debug("Starting entity::change_cdrom sub");
    my $vmname = Opts::get_option('vmname');
    my $num = Opts::get_option('num');
    my $iso = Opts::get_option('iso') || 0;
    my $unmount = Opts::get_option('unmount') || 0;
    &Log::debug("Requested options, vmname=>'$vmname', num=>'$num', iso=>'$iso', unmount=>'$unmount'");
    if ( $unmount and $iso ) {
        Vcenter::Opts->throw( error => 'iso and unmount both specified', opt => "unmount and iso");
    } elsif ( $unmount ) {
        my $spec = &Guest::remove_cdrom_iso_spec( $vmname, $num );
        &Guest::reconfig_vm( $vmname ,$spec );
    } elsif ( $iso ) {
        if ( &VCenter::datastore_file_exists( $iso) ) {
            my $spec = &Guest::change_cdrom_iso_spec( $vmname, $num, $iso );
            &Guest::reconfig_vm( $vmname ,$spec );
        } else {
            Vcenter::Path->throw( error => 'Datastore file could not be found', path => $iso);
        }
    } else {
        Vcenter::Opts->throw( error => 'iso or unmount not specified', opt => "unmount and iso");
    }
    return 1;
}

sub change_interface {
    &Log::debug("Starting Entity::change_interface sub");
    my $vmname = Opts::get_option('vmname');
    my $num = Opts::get_option('num');
    my $network = Opts::get_option('network');
    &Log::debug("Opts are, vmname=>'$vmname', num=>'$num', network=>'$network'");
    my $spec = &Guest::change_interface_spec( $vmname, $num, $network);
#    &Guest::reconfig_vm( $vmname ,$spec );
    return 1;
}

#tested
sub change_snapshot {
    &Log::debug("Entity::change_snapshot sub started");
    my $vmname = Opts::get_option('vmname');
    my $id     = Opts::get_option('id');
    &Log::debug("Requested options, vmname=>'$vmname', id=>'$id'");
    &Guest::revert_to_snapshot( $vmname, $id );
    return 1;
}

#tested
sub add_snapshot {
    &Log::debug("Entity::add_snapshot sub started");
    my $vmname    = Opts::get_option('vmname');
    my $snap_name = Opts::get_option('snap_name');
    my $desc      = Opts::get_option('desc');
    &Log::debug( "Requested options, vmname=>'"
          . $vmname
          . "', snap_name=>'"
          . $snap_name
          . "', desc=>'"
          . $desc
          . "'" );
    &Guest::create_snapshot( $vmname, $snap_name, $desc );
    &Log::info("Finished creating snapshot");
    return 1;
}

sub add_interface {
    &Log::debug("Entity::add_interface sub started");
    my $vmname = Opts::get_option('vmname');
    my $type   = Opts::get_option('type');
    &Log::debug("Requested option, vmname=>'$vmname'");
    my $spec = &Guest::add_interface_spec( $vmname, $type );
    &Guest::reconfig_vm( $vmname, $spec );
    &Log::info("Finished adding interface");
    return 1;
}

#tested
sub add_cdrom {
    &Log::debug("Entity::add_cdrom sub started");
    my $vmname = Opts::get_option('vmname');
    &Log::debug("Requested option, vmname=>'$vmname'");
    my $spec = &Guest::add_cdrom_spec($vmname);
    &Guest::reconfig_vm( $vmname, $spec );
    &Log::info("Finished adding cdrom");
    return 1;
}

#teted
sub add_disk {
    &Log::debug("Entity::add_cdrom sub started");
    my $vmname = Opts::get_option('vmname');
    my $size   = Opts::get_option('size') * 1024;
    &Log::debug("Requested option, vmname=>'$vmname', size=>'$size'");
    my $spec = &Guest::add_disk_spec( $vmname, $size );
    &Guest::reconfig_vm( $vmname, $spec );
    &Log::info("Finished adding disk");
    return 1;
}

#tested
sub clone_vm {
    &Log::debug("Entity::clone sub started");
    my $parent_pool = Opts::get_option('parent_pool');
    my $ticket      = Opts::get_option('ticket');
    my $os_temp     = Opts::get_option('os_temp');
    &Support::get_key_info( 'template', $os_temp );
    my $domain = Opts::get_option('domain');
    &Log::info(
"Arguments: parent_pool=>'$parent_pool', ticket=>'$ticket', os_temp=>'$os_temp', domain=>'$domain'"
    );
    &Log::debug("Get os_temp object for cloning and information");
    my $os_temp_path = &Support::get_key_value( 'template', $os_temp, 'path' );
    my $os_temp_view =
      &VCenter::moref2view( &VCenter::path2moref($os_temp_path) );
    &Log::debug("Gathering hw information for cloneing");
    my ( $memory, $cpu );

    if ( defined( Opts::get_option('memory') ) ) {
        $memory = Opts::get_option('memory');
    }
    else {
        my $view =
          &Guest::entity_property_view( $os_temp_view->name, 'VirtualMachine',
            'summary.config.memorySizeMB' );
        $memory = $view->get_property('summary.config.memorySizeMB');
    }
    if ( defined( Opts::get_option('cpu') ) ) {
        $cpu = Opts::get_option('cpu');
    }
    else {
        my $view =
          &Guest::entity_property_view( $os_temp_view->name, 'VirtualMachine',
            'summary.config.numCpu' );
        $cpu = $view->get_property('summary.config.numCpu');
    }
    &Log::info("Memory and cpu, memory=>'$memory', cpu=>'$cpu'");
    &Log::debug("Checking if parent resource pool exists");
    &VCenter::num_check( $parent_pool, 'ResourcePool' );
    if ( !&VCenter::exists_entity( $ticket, 'ResourcePool' ) ) {
        &Log::info("Ticket resource pool does not exist. Creating");
        &VCenter::create_resource_pool( $ticket, $parent_pool );
    }
    if ( !&VCenter::exists_entity( $os_temp, 'Folder' ) ) {
        &Log::info("Linked clone folder does not exist. Creating");
        &VCenter::linked_clone_folder($os_temp);
    }
    &Log::debug("Retrieving last snapshot to attach to");
    my $snapshot_view;
    if (   defined( $os_temp_view->snapshot )
        && defined( $os_temp_view->snapshot->rootSnapshotList ) )
    {
        $snapshot_view = $os_temp_view->snapshot->rootSnapshotList;
    }
    else {
        Entity::Snapshot->throw(
            error    => 'Template has no snapshots defined',
            entity   => $os_temp,
            snapshot => 'none'
        );
    }
    if ( defined( $snapshot_view->[0]->{'childSnapshotList'} ) ) {
        &Log::debug("Recursion for last snapshot");
        $snapshot_view =
          &Guest::find_last_snapshot(
            $snapshot_view->[0]->{'childSnapshotList'} );
        &Log::debug("End of recursion");
    }
    $snapshot_view = &VCenter::moref2view( $snapshot_view->[0]->{'snapshot'} );
    &Log::debug("Generating uniq vmname");
    my $vmname =
      &Misc::uniq_vmname( $ticket, Opts::get_option('username'), $os_temp );
    &Log::debug("Generating Relocate spec");
    my $relocate_spec = &Support::RelocateSpec($ticket);
    &Log::debug("Generating Config spec");
    my $config_spec = &Support::ConfigSpec( $memory, $cpu, $os_temp );
    &Log::debug("Generating Clone spec");
    my $clone_spec;

    if ( &Support::get_key_value( 'template', $os_temp, 'os' ) =~ /win/ ) {
        &Log::debug("Generating Clone spec for Windows");
        $clone_spec =
          &Support::win_CloneSpec( $os_temp_view->name, $snapshot_view,
            $relocate_spec, $config_spec, $domain,
            &Support::get_key_value( 'template', $os_temp, 'key' ) );
    }
    elsif ( &Support::get_key_value( 'template', $os_temp, 'os' ) =~ /lin/ ) {
        &Log::debug("Generating Clone spec for SDK supported linux machines");
        $clone_spec = &Support::lin_CloneSpec(
            $os_temp_view->name, $snapshot_view,
            $relocate_spec,      $config_spec
        );
    }
    else {
        &Log::debug("Generating Clone spec for other");
        $clone_spec =
          &Support::oth_CloneSpec( $snapshot_view, $relocate_spec,
            $config_spec );
    }
    &VCenter::clonevm( $os_temp_view->name, $vmname, $os_temp, $clone_spec );
    print "=" x 40 . "\n";
    print "Machine is provisioned\n";
    print "Login: '"
      . &Support::get_key_value( 'template', $os_temp, 'username' ) . "'/'"
      . &Support::get_key_value( 'template', $os_temp, 'password' ) . "'\n";
    print "Unique name of vm: $vmname\n";
    return 1;
}

sub info_dumper {
    &Log::debug("Entity::info_dumper sub started");
    my $vmname = Opts::get_option('vmname');
    &Log::debug("Vmname requested=>'$vmname'");
    my $view = &Guest::entity_full_view( $vmname, 'VirtualMachine' );
    print Dumper($view);
    return 1;
}

sub info_runtime {
    &Log::debug("Entity::info_runtime sub started");
    my $vmname = Opts::get_option('vmname');
    &Log::debug("Vmname requested=>'$vmname'");
    my $view =
      &Guest::entity_property_view( $vmname, 'VirtualMachine', 'runtime' );
    print Dumper($view);
    return 1;
}

sub run_command {
    &Log::debug("Starting entity::run sub");
    my %opts = ();
    $opts{vmname} = Opts::get_option('vmname');
    my $vm_info = &Misc::vmname_splitter( $opts{vmname} );
    $opts{guestusername} = Opts::get_option('guestusername')
      || &Support::get_key_value( 'template', $vm_info->{template},
        'username' );
    $opts{guestpassword} = Opts::get_option('guestpassword')
      || &Support::get_key_value( 'template', $vm_info->{template},
        'password' );
    $opts{prog}     = Opts::get_option('prog');
    $opts{prog_arg} = Opts::get_option('prog_arg');
    $opts{workdir}  = Opts::get_option('workdir');
    $opts{env}      = Opts::get_option('env');
    &Log::loghash( "Opts are, ", \%opts );
    my $pid = &Guest::run_command( \%opts );
    print "Pid of command:'$pid'\n";
    return 1;
}

sub transfer {
    &Log::debug("Starting entity::transfer sub");
    my %opts = ();
    $opts{type}   = Opts::get_option('type');
    $opts{vmname} = Opts::get_option('vmname');
    my $vm_info = &Misc::vmname_splitter( $opts{vmname} );
    $opts{guestusername} = Opts::get_option('guestusername')
      || &Support::get_key_value( 'template', $vm_info->{template},
        'username' );
    $opts{guestpassword} = Opts::get_option('guestpassword')
      || &Support::get_key_value( 'template', $vm_info->{template},
        'password' );
    $opts{source}    = Opts::get_option('source');
    $opts{dest}      = Opts::get_option('dest');
    $opts{overwrite} = Opts::get_option('overwrite');
    &Log::loghash( "Opts are, ", \%opts );

    if ( $opts{type} eq "to" ) {
        &Guest::transfer_to_guest( \%opts );
    }
    elsif ( $opts{type} eq "from" ) {
        &Guest::transfer_from_guest( \%opts );
    }
    else {
        Vcenter::Opt->throw(
            error => 'Unrecognized opt given type,',
            opt   => $opts{type}
        );
    }
    return 1;
}

#tested
sub delete_vm {
    &Log::debug("Entity::delete_vm sub started");
    my $vmname = Opts::get_option('vmname');
    &Log::debug("Vmname requested=>'$vmname'");
    &VCenter::destroy_entity( $vmname, 'VirtualMachine' );
    if ( &VCenter::exists_entity( $vmname, 'VirtualMachine' ) ) {
        Entity::NumException->throw(
            error  => 'VM was not deleted succcesfully',
            entity => $vmname,
            count  => '1'
        );
    }
    else {
        &Log::info("Entity deleted succesfully");
    }
    return 1;
}

#tested
sub delete_snapshot {
    &Log::debug("Entity::delete_snapshot sub started");
    my $vmname = Opts::get_option('vmname');
    my $id     = Opts::get_option('id') || 0;
    my $all    = Opts::get_option('all');
    &Log::debug("Arguments are, vmname=>'$vmname', id=>'$id', all=>'$all'");
    if ($all) {
        &Log::debug("All snapshots need to be removed");
        &Guest::remove_all_snapshots($vmname);
    }
    elsif ($id) {
        &Log::debug("$id snapshot need to be removed");
        &Guest::remove_snapshot( $vmname, $id );
    }
    else {
        &Log::warning("Please give either all or id");
    }
    &Log::info("Snapshot delete sub completed");
    return 1;
}

sub delete_cdrom {
    &Log::debug("Starting entity::delete_cdrom sub");
    my $vmname = &Opts::get_option('vmname');
    my $id = &Opts::get_option('id');
    &Log::debug("Options, vmname=>'$vmname', id=>'$id'");
    my @cdrom_hw = @{ &Guest::get_hw( $vmname, 'VirtualCdrom' ) };
    &Guest::remove_hw($vmname, $cdrom_hw[$id]);
    return 1;
}

sub delete_disk {
    &Log::debug("Starting entity::delete_disk sub");
    my $vmname = &Opts::get_option('vmname');
    my $id = &Opts::get_option('id');
    &Log::debug("Options, vmname=>'$vmname', id=>'$id'");
    my @disk_hw = @{ &Guest::get_hw( $vmname, 'VirtualDisk' ) };
    &Guest::remove_hw($vmname, $disk_hw[$id]);
    return 1;
}

sub delete_interface {
    &Log::debug("Starting entity::delete_cdrom sub");
    my $vmname = &Opts::get_option('vmname');
    my $id = &Opts::get_option('id');
    &Log::debug("Options, vmname=>'$vmname', id=>'$id'");
    my @net_hw = @{ &Guest::get_hw( $vmname, 'VirtualEthernetCard' ) };
    &Guest::remove_hw( $vmname, $net_hw[$id]);
    return 1;
}

sub delete_resourcepool {
    &Log::debug("Starting entity::delete_resourcepool sub");
    my $name = &Opts::get_option('name');
    &Log::debug("Opts: name=>'$name'");
    if ( &VCenter::check_if_empty_entity( $name, 'ResourcePool') ) {
        &VCenter::destroy_entity( $name, 'ResourcePool' );
    } else {
        &Log::critical("ResourcePool is not empty");
        exit;
    }
    return 1;
}

sub delete_folder {
    &Log::debug("Starting entity::delete_folder sub");
    my $name = &Opts::get_option('name');
    &Log::debug("Opts: name=>'$name'");
    if ( &VCenter::check_if_empty_entity( $name, 'Folder') ) {
        &VCenter::destroy_entity( $name, 'Folder' );
    } else {
        &Log::critical("Folder is not empty");
        exit;
    }
    return 1;
}

sub add_folder {
    &Log::debug("Starting entity::add_folder sub");
    &VCenter::create_folder( &Opts::get_option('name'), &Opts::get_option('parent') );
    return 1;
}

sub add_resourcepool {
    &Log::debug("Starting entity::add_resourcepool sub");
    &VCenter::create_resource_pool( &Opts::get_option('name'), &Opts::get_option('parent') );
    return 1;
}

sub promote {
    &Log::debug("Starting Entity::promote sub");
    my $vmname = &Opts::get_option('vmname');
    &Log::debug("Opts are, vmname=>'$vmname'");
    &Guest::promote( $vmname );
    &Log::debug("Finished Entity::promote sub");
    return 1;
}

1;
__END__
