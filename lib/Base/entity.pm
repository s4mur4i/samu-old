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
                cdrom    => { helper => 'AUTHOR', function => \&add_cdrom },
                network  => { helper => 'AUTHOR', function => \&add_network },
                disk     => { helper => 'AUTHOR', function => \&add_disk },
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
                    },
                },
                network => {
                    function => \&delete_network,
                    opts     => {
                        vmname => {
                            type     => '=s',
                            help     => 'Which VMs cdrom to list.',
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
                    },
                },
                snapshot => {
                    function => \&delete_snapshot,
                    opts     => {
                        vmname => {
                            type     => '=s',
                            help     => 'Which VMs cdrom to list.',
                            required => '1',
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
                network => {
                    function => \&list_network,
                    opts     => {
                        vmname => {
                            type     => '=s',
                            help     => 'Which VMs network to list.',
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
                            help     => 'Which VMs disk to list.',
                            required => '1',
                        },
                    },
                },
                network => {
                    function => \&change_network,
                    opts     => {
                        vmname => {
                            type     => '=s',
                            help     => 'Which VMs cdrom to list.',
                            required => '1',
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
    },
};

sub main {
    &Log::debug("Entity::main sub started");
    &misc::option_parser( $module_opts, "main" );
}

sub list_cdrom {
    &Log::debug("Entity::list_cdrom sub started");
    my $vmname = Opts::get_option('vmname');
    &Log::debug("Requested options, vmname=>'$vmname'");
    my @cdrom_hw = &Guest::get_hw( $vmname, 'VirtualCdrom' );
    for ( my $i = 0 ; $i < scalar(@cdrom_hw) ; $i++ ) {
        &Log::debug("Iterating thorugh CDrom hardware '$i'");
        my $backing = "Unknown";
        if ( ${ $cdrom_hw[$i] }->backing->isa('VirtualCdromIsoBackingInfo') ) {
            &Log::debug("Backing is a file backing");
            $backing = ${ $cdrom_hw[$i] }->backing->fileName;
        }
        elsif ( ${ $cdrom_hw[$i] }
            ->backing->isa('VirtualCdromRemotePassthroughBackingInfo') )
        {
            &Log::debug("Backing is a remote pas through backing");
            $backing = "Host Device";
        }
        print
"number=>'$i', key=>'${$cdrom_hw[$i]}->key', backing=>'$backing', label=>'${$cdrom_hw[$i]}->label'\n";
    }
    &Log::debug("Finished list_cdrom sub");
    return 1;
}

sub list_network {
    &Log::debug("Entity::list_network sub started");
    my $vmname = Opts::get_option('vmname');
    &Log::debug("Requested options, vmname=>'$vmname'");
    return 1;
}

sub list_disk {
    &Log::debug("Entity::list_disk sub started");
    my $vmname = Opts::get_option('vmname');
    &Log::debug("Requested options, vmname=>'$vmname'");
    my @disk_hw = &Guest::get_hw( $vmname, 'VirtualDisk' );
    for ( my $i = 0 ; $i < scalar(@disk_hw) ; $i++ ) {
        &Log::debug("Iterating thorugh disk hardware '$i'");
        print
"number=>'$i', key=>'${$disk_hw[$i]}->key', size=>'${$disk_hw[$i]}->capacityInKB' KB, path=>${$disk_hw[$i]}->backing->fileName\n";
    }
    &Log::debug("Finished list_disk sub");
    return 1;
}

sub change_altername {
    &Log::debug("Entity::change_altername sub started");
    my $vmname = Opts::get_option('vmname');
    my $name   = Opts::get_option('name');
    &Log::debug("Requested options, vmname=>'$vmname', name=>'$name'");
    &Guest::change_altername( $vmname, $name );
    return 1;
}

sub change_snapshot {
    &Log::debug("Entity::list_snapshot sub started");
    my $vmname = Opts::get_option('vmname');
    my $id     = Opts::get_option('id');
    &Log::debug("Requested options, vmname=>'$vmname', id=>'$id'");
    &Guest::revert_to_snapshot_id( $vmname, $id );
    return 1;
}

sub list_snapshot {
    &Log::debug("Entity::list_snapshot sub started");
    my $vmname = Opts::get_option('vmname');
    &Log::debug("Requested options, vmname=>'$vmname'");
    &Guest::list_snapshot($vmname);
    return 1;
}

sub add_snapshot {
    &Log::debug("Entity::add_snapshot sub started");
    my $vmname    = Opts::get_option('vmname');
    my $snap_name = Opts::get_option('snap_name');
    my $desc      = Opts::get_option('desc');
    &Log::debug(
"Requested options, vmname=>'$vmname', snap_name=>'$snap_name', desc=>'$desc'"
    );
    &Guest::create_snapshot( $vmname, $snap_name, $desc );
    &Log::info("Finished creating snapshot");
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
        $memory = &Guest::entity_property_view( $os_temp_view->name, 'VirtualMachine', 'summary.config.memorySizeMB' );
    }
    if ( defined( Opts::get_option('cpu') ) ) {
        $cpu = Opts::get_option('cpu');
    }
    else {
        $cpu = &Guest::entity_property_view( $os_temp_view->name, 'VirtualMachine', 'summary.config.numCpu' );
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

1;
__END__
