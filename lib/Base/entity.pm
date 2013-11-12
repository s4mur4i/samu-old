package entity;

use strict;
use warnings;
use Base::misc;

my $help = 0;

=pod

=head1 entity.pm

Subroutines from Base/entity.pm

=cut

BEGIN {
    use Exporter();
    our ( @ISA, @EXPORT );

    @ISA    = qw(Exporter);
    @EXPORT = qw();
}

our $module_opts = {
    helper    => 'VM',
    functions => {
        clone => {
            function        => \&clone_vm,
            vcenter_connect => 1,
            opts            => {
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
                    default  => "Resources",
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
                    help => "Should the requested machine be added to support.ittest.domain",
                    required => 0,
                    default  => 0,
                },
                altername => {
                    type => "=s",
                    help => "What should the altername be changed to",
                    required => 0,
                    default  => "",
                },
            },
        },
        convert_full => {
            function        => \&promote,
            vcenter_connect => 1,
            opts            => {
                vmname => {
                    type     => "=s",
                    help     => "Which machine to convert",
                    required => 1,
                },
            },
        },
        info => {
            helper          => "VM_functions/VM_info_function",
            vcenter_connect => 1,
            functions       => {
                dumper => {
                    function        => \&info_dumper,
                    prereq_module   => [qw(Data::Dumper)],
                    vcenter_connect => 1,
                    opts            => {
                        vmname => {
                            type => "=s",
                            help =>
                              "The vm's name which information should be dump",
                            required => 1,
                        },
                    },
                },
                runtime => {
                    function        => \&info_runtime,
                    prereq_module   => [qw(Data::Dumper)],
                    vcenter_connect => 1,
                    opts            => {
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
            helper    => "VM_functions/VM_add_function",
            functions => {
                cdrom => {
                    function        => \&add_cdrom,
                    vcenter_connect => 1,
                    opts            => {
                        vmname => {
                            type => "=s",
                            help => "The vm's name where cdrom should be added",
                            required => 1,
                        },
                    },
                },
                interface => {
                    function        => \&add_interface,
                    vcenter_connect => 1,
                    opts            => {
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
                    function        => \&add_disk,
                    vcenter_connect => 1,
                    opts            => {
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
                    function        => \&add_snapshot,
                    vcenter_connect => 1,
                    opts            => {
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
                    function        => \&add_folder,
                    vcenter_connect => 1,
                    opts            => {
                        name => {
                            type     => "=s",
                            help     => "Name of folder to create",
                            required => 1,
                        },
                        parent => {
                            type     => "=s",
                            help     => "Name of parent to create in",
                            required => 0,
                            default  => "vm",
                        },
                    },
                },
                resourcepool => {
                    function        => \&add_resourcepool,
                    vcenter_connect => 1,
                    opts            => {
                        name => {
                            type     => "=s",
                            help     => "Name of folder to create",
                            required => 1,
                        },
                        parent => {
                            type     => "=s",
                            help     => "Name of parent to create in",
                            required => 0,
                            default  => "resources",
                        },
                    },
                },
            },
        },
        delete => {
            helper    => 'VM_functions/VM_delete_function',
            functions => {
                hw => {
                    function        => \&delete_hw,
                    vcenter_connect => 1,
                    opts            => {
                        vmname => {
                            type     => "=s",
                            help     => "Name of virtual machine",
                            required => 1,
                        },
                        id => {
                            type     => "=s",
                            help     => "Which device to delete",
                            required => 1,
                        },
                        hw => {
                            type     => "=s",
                            help     => "What hw to delete",
                            required => 1,
                        },
                    },
                },
                snapshot => {
                    function        => \&delete_snapshot,
                    vcenter_connect => 1,
                    opts            => {
                        vmname => {
                            type     => "=s",
                            help     => "Which VMs snapshot to delete",
                            required => 1,
                        },
                        id => {
                            type     => "=s",
                            help     => "Id of snapshot to delete",
                            required => 0,
                        },
                        all => {
                            type     => "",
                            help     => "Delete all snapshots",
                            required => 0,
                        },
                    },
                },
                entity => {
                    function        => \&delete_entity,
                    vcenter_connect => 1,
                    opts            => {
                        name => {
                            type     => "=s",
                            help     => "Name of entity to delete",
                            required => 1,
                        },
                        type => {
                            type     => "=s",
                            help     => "Type of entity to delete",
                            required => 1,
                        },
                    },
                },
            },
        },
        list => {
            helper    => "VM_functions/VM_list_function",
            functions => {
                cdrom => {
                    function        => \&list_cdrom,
                    vcenter_connect => 1,
                    opts            => {
                        vmname => {
                            type     => "=s",
                            help     => "Which VMs cdrom to list",
                            required => 1,
                        },
                        output => {
                            type     => "=s",
                            help     => "Output type, table/csv",
                            default  => "table",
                            required => 0,
                        },
                        noheader => {
                            type     => "",
                            help     => "Should header information be printed",
                            required => 0,
                        },
                    },
                },
                interface => {
                    function        => \&list_interface,
                    vcenter_connect => 1,
                    opts            => {
                        vmname => {
                            type     => "=s",
                            help     => "Which VMs interface to list",
                            required => 1,
                        },
                        output => {
                            type     => "=s",
                            help     => "Output type, table/csv",
                            default  => "table",
                            required => 0,
                        },
                        noheader => {
                            type     => "",
                            help     => "Should header information be printed",
                            required => 0,
                        },
                    },
                },
                disk => {
                    function        => \&list_disk,
                    vcenter_connect => 1,
                    opts            => {
                        vmname => {
                            type     => "=s",
                            help     => "Which VMs disk to list",
                            required => 1,
                        },
                        output => {
                            type     => "=s",
                            help     => "Output type, table/csv",
                            default  => "table",
                            required => 0,
                        },
                        noheader => {
                            type     => "",
                            help     => "Should header information be printed",
                            required => 0,
                        },
                    },
                },
                snapshot => {
                    function        => \&list_snapshot,
                    vcenter_connect => 1,
                    opts            => {
                        vmname => {
                            type     => "=s",
                            help     => "Name of vm to list snapshot",
                            required => 1,
                        },
                        output => {
                            type     => "=s",
                            help     => "Output type, table/csv",
                            default  => "table",
                            required => 0,
                        },
                        noheader => {
                            type     => "",
                            help     => "Should header information be printed",
                            required => 0,
                        },
                    },
                },
                process => {
                    function        => \&list_process,
                    vcenter_connect => 1,
                    opts            => {
                        vmname => {
                            type     => "=s",
                            help     => "Name of Virtual Machine",
                            required => 1,
                        },
                        guestusername => {
                            type     => "=s",
                            help     => "Username to authenticate with",
                            required => 0,
                        },
                        guestpassword => {
                            type     => "=s",
                            help     => "Password to authenticate with",
                            required => 0,
                        },
                        pid => {
                            type     => "=s",
                            help     => "Pid to get information about",
                            required => 0,
                            default  => 0,
                        },
                        output => {
                            type     => "=s",
                            help     => "Output type, table/csv",
                            default  => "table",
                            required => 0,
                        },
                        noheader => {
                            type     => "",
                            help     => "Should header information be printed",
                            required => 0,
                        },
                    },
                },
                events => {
                    function        => \&list_events,
                    vcenter_connect => 1,
                    opts            => {
                        vmname => {
                            type     => "=s",
                            help     => "Name of Virtual Machine",
                            required => 1,
                        },
                        output => {
                            type     => "=s",
                            help     => "Output type, table/csv",
                            default  => "table",
                            required => 0,
                        },
                        noheader => {
                            type     => "",
                            help     => "Should header information be printed",
                            required => 0,
                        },
                    },
                },
                templates => {
                    function        => \&list_templates,
                    vcenter_connect => 0,
                    opts            => {
                        output => {
                            type     => "=s",
                            help     => "Output type, table/csv",
                            default  => "table",
                            required => 0,
                        },
                        noheader => {
                            type     => "",
                            help     => "Should header information be printed",
                            required => 0,
                            default  => 0,
                        },
                    },
                },
            },
        },
        change => {
            helper    => "VM_functions/VM_change_function",
            functions => {
                cdrom => {
                    function        => \&change_cdrom,
                    vcenter_connect => 1,
                    opts            => {
                        vmname => {
                            type     => "=s",
                            help     => "Which VMs disk to list",
                            required => 1,
                        },
                        num => {
                            type     => "=s",
                            help     => "Which cdrom to change",
                            required => 1,
                        },
                        iso => {
                            type     => "=s",
                            help     => "Which iso to add",
                            required => 0,
                        },
                        unmount => {
                            type     => "",
                            help     => "Unmount and iso",
                            required => 0,
                        },
                    },
                },
                interface => {
                    function        => \&change_interface,
                    vcenter_connect => 1,
                    opts            => {
                        vmname => {
                            type     => "=s",
                            help     => "Name of vm",
                            required => 1,
                        },
                        num => {
                            type     => "=s",
                            help     => "Which interface to manage",
                            required => 1,
                        },
                        network => {
                            type     => "=s",
                            help     => "Which network to change to",
                            required => 0,
                            default  => "VLAN21",
                        },
                    },
                },
                altername => {
                    function        => \&change_altername,
                    vcenter_connect => 1,
                    opts            => {
                        vmname => {
                            type     => "=s",
                            help     => "Name of vm",
                            required => 1,
                        },
                        name => {
                            type     => "=s",
                            help     => "Name of new alternate name for vm",
                            required => 1,
                        },
                    },
                },
                snapshot => {
                    function        => \&change_snapshot,
                    vcenter_connect => 1,
                    opts            => {
                        vmname => {
                            type     => "=s",
                            help     => "Name of vm",
                            required => 1,
                        },
                        id => {
                            type     => "=s",
                            help     => "ID of snapshot to revert to",
                            required => 1,
                        },
                    },
                },
                power => {
                    function        => \&change_power,
                    vcenter_connect => 1,
                    opts            => {
                        vmname => {
                            type     => "=s",
                            help     => "Name of vm",
                            required => 1,
                        },
                        state => {
                            type => "=s",
                            help =>
"What state should the vm be put in. Possible: on/off",
                            required => 1,
                        },
                    },
                },
            },
        },
        run => {
            prereq_module   => [qw(LWP::UserAgent)],
            vcenter_connect => 1,
            function        => \&run_command,
            opts            => {
                vmname => {
                    type     => "=s",
                    help     => "Which VMs should be used for running command",
                    required => 1,
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
            function        => \&transfer,
            vcenter_connect => 1,
            prereq_module   => [qw(LWP::Simple HTTP::Request LWP::UserAgent)],
            opts            => {
                type => {
                    type     => "=s",
                    help     => "Diretion of transfer, Values: to/from",
                    required => 1,
                },
                vmname => {
                    type     => "=s",
                    help     => "Which VMs should be used for transfer",
                    required => 1,
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
        customization_status => {
            function        => \&customization_status,
            vcenter_connect => 1,
            opts            => {
                vmname => {
                    type     => "=s",
                    help     => "Which VMs should be used for transfer",
                    required => 1,
                },
                wait => {
                    type     => "",
                    help     => "Should script wait for success of failure",
                    required => 0,
                },
            },
        },
    },
};

=pod

=head1 module_opts

=head2 PURPOSE

Return Module_opts hash for testing

=head2 PARAMETERS

=over

=back

=head2 RETURNS

Hash ref containing module_opts

=head2 DESCRIPTION

=head2 THROWS

=head2 COMMENTS

=head2 TEST COVERAGE

=cut

sub module_opts {
    return $module_opts;
}

=pod

=head2 main

=head3 PURPOSE

This is main entry point for Entity module

=head3 PARAMETERS

=over

=back

=head3 RETURNS

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

=head3 TEST COVERAGE

=cut

sub main {
    &Log::debug("Starting Entity::main sub");
    &misc::option_parser( $module_opts, "main" );
    &Log::debug("Finishing Entity::main sub");
    return 1;
}

=pod

=head2 list_cdrom

=head3 PURPOSE

List all cdroms attached to a vm

=head3 PARAMETERS

=over

=item vmname

Name of Virtual Machine

=item noheader

Should header row be printed

=item output

Type of output table or csv

=back

=head3 RETURNS

True on success

=head3 DESCRIPTION

=head3 THROWS

Vcenter::Opts if unknown output requested

=head3 COMMENTS

=head3 TEST COVERAGE

Tested if list outputs as required

=cut

sub list_cdrom {
    &Log::debug("Starting Entity::list_cdrom sub");
    my $vmname = Opts::get_option('vmname');
    &Log::debug1("Opts are: vmname=>'$vmname'");
    my @titles = (qw(Number Key Size Path));
    &Output::option_parser( \@titles );
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
            $backing = "Client_Device";
        }
        elsif ( $cdrom_hw[$i]->{backing}->isa('VirtualCdromAtapiBackingInfo') )
        {
            &Log::debug("Backing is a Host device backing");
            $backing = $cdrom_hw[$i]->{backing}->{deviceName};
        }
        my $label = $cdrom_hw[$i]->{deviceInfo}->{label} || "None";
        &Output::add_row( [ $i, $cdrom_hw[$i]->{key}, "$backing", "$label" ] );
    }
    &Output::print;
    &Log::debug("Finishing Entity::list_cdrom sub");
    return 1;
}

=pod

=head2 list_interface

=head3 PURPOSE

List interfaces and information

=head3 PARAMETERS

=over

=item vmname

Name of Virtual Machine

=item noheader

Should header row be printed

=item output

Type of output table or csv

=back

=head3 RETURNS

True on success

=head3 DESCRIPTION

=head3 THROWS

Vcenter::Opts if unknown output requested

=head3 COMMENTS

=head3 TEST COVERAGE

Tested if output is as expected

=cut

sub list_interface {
    &Log::debug("Entity::list_interface sub started");
    my $vmname = Opts::get_option('vmname');
    &Log::debug1("Opts are: vmname=>'$vmname'");
    my @titles = (qw(Number Key MacAddress Label Network InterfaceType));
    &Output::option_parser( \@titles );
    my @net_hw = @{ &Guest::get_hw( $vmname, 'VirtualEthernetCard' ) };
    if ( @net_hw eq 0 ) {
        &Log::debug("No interface on entity");
        print "Currently no interfaces attached to machine\n";
    }
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
        &Output::add_row(
            [
                $i,
                $net_hw[$i]->{key},
                $net_hw[$i]->{macAddress},
                $net_hw[$i]->{deviceInfo}->{label},
                $net_hw[$i]->{deviceInfo}->{summary},
                $type
            ]
        );
    }
    &Output::print;
    &Log::debug("Finishing Entity::list_interface sub");
    return 1;
}

=pod

=head2 list_disk

=head3 PURPOSE

List disk attached to Virtual Machine

=head3 PARAMETERS

=over

=item vmname

Name of Virtual Machine

=item noheader

Should header row be printed

=item output

Type of output table or csv

=back

=head3 RETURNS

True on success

=head3 DESCRIPTION

=head3 THROWS

Vcenter::Opts if unknown output requested

=head3 COMMENTS

=head3 TEST COVERAGE

Tested if lists as expected

=cut

sub list_disk {
    &Log::debug("Starting Entity::list_disk sub");
    my $vmname = Opts::get_option('vmname');
    &Log::debug1("Opts are: vmname=>'$vmname'");
    my @titles = (qw(Number Key Size Path));
    &Output::option_parser( \@titles );
    my @disk_hw = @{ &Guest::get_hw( $vmname, 'VirtualDisk' ) };
    &Log::dumpobj( "disk_hw", \@disk_hw );
    if ( @disk_hw eq 0 ) {
        &Log::debug("No disks on entity");
        print "Currently no disk attached to machine\n";
    }
    for ( my $i = 0 ; $i < scalar(@disk_hw) ; $i++ ) {
        &Log::debug("Iterating thorugh disk hardware '$i'");
        &Log::dumpobj( "disk $i", $disk_hw[$i] );
        &Output::add_row(
            [
                $i,
                $disk_hw[$i]->{key},
                $disk_hw[$i]->{capacityInKB},
                $disk_hw[$i]->{backing}->{fileName}
            ]
        );
    }
    &Output::print;
    &Log::debug("Finishing list_disk sub");
    return 1;
}

=pod

=head2 list_snapshot

=head3 PURPOSE

To list snapshot information

=head3 PARAMETERS

=over

=item vmname

Name of Virtual Machine

=back

=head3 RETURNS

True on success

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

Output is only generated from first rootsnapshotlist branch. There should be a solution to iterate through all elements

=head3 TEST COVERAGE

Tested if list returns as expected, also tested if exception is thrown

=cut

sub list_snapshot {
    &Log::debug("Starting Entity::list_snapshot sub");
    my $vmname = Opts::get_option('vmname');
    &Log::debug1("Opts are: vmname=>'$vmname'");
    my $snapshotinfo = {};
    my $view =
      &Guest::entity_property_view( $vmname, 'VirtualMachine', 'snapshot' );
    if ( !defined( $view->{snapshot} ) ) {
        Entity::Snapshot->throw(
            error    => "Entity has no snapshots defined",
            entity   => $vmname,
            snapshot => 0
        );
    }
    my @titles = (qw(Current ID Name CreateTime Description));
    &Output::option_parser( \@titles );
    $snapshotinfo = { CUR => $view->snapshot->currentSnapshot->value };
    $snapshotinfo =
      &Guest::list_snapshot( $snapshotinfo,
        $view->{snapshot}->{rootSnapshotList}[0] );
    delete $snapshotinfo->{CUR};
    for my $id ( sort { $a <=> $b } keys %$snapshotinfo ) {
        &Output::add_row(
            [
                defined( $snapshotinfo->{$id}->{current} ) ? "CUR" : "---",
                $id,
                $snapshotinfo->{$id}->{name},
                $snapshotinfo->{$id}->{createTime},
                $snapshotinfo->{$id}->{description}
            ]
        );
    }
    &Output::print;
    &Log::debug("Finishing Entity::list_snapshot sub");
    return 1;
}

=pod

=head1 list_process

=head2 PURPOSE

List processes in Virtual Machine

=head2 PARAMETERS

=over

=item pid

Pid of requested program

=item guestusername

Username to authenticate with

=item guestpassword

Password to authenticate with

=item vmname

Name of Virtual Machine

=back

=head2 RETURNS

True on success

=head2 DESCRIPTION

=head2 THROWS

=head2 COMMENTS

=head2 TEST COVERAGE

=cut

sub list_process {
    &Log::debug("Starting Entity::list_process sub");
    my %arguments;
    $arguments{'vmname'} = &Opts::get_option('vmname');
    my $vm_info = &Misc::vmname_splitter( $arguments{vmname} );
    $arguments{'guestusername'} = &Opts::get_option('guestusername')
      || &Support::get_key_value( 'template', $vm_info->{template},
        'username' );
    $arguments{'guestpassword'} = &Opts::get_option('guestpassword')
      || &Support::get_key_value( 'template', $vm_info->{template},
        'password' );
    $arguments{'pid'} = &Opts::get_option('pid');
    my @titles = (qw(pid owner name command startTime endTime exitCode));
    &Output::option_parser( \@titles );
    my $programs = &Guest::process_info( \%arguments );

    for my $prog (@$programs) {
        &Log::dumpobj( "prog", $prog );
        &Output::add_row(
            [
                $prog->{pid},
                $prog->{owner}     // "---",
                $prog->{name}      // "---",
                $prog->{cmdLine}   // "---",
                $prog->{startTime} // "---",
                $prog->{endTime}   // "---",
                $prog->{exitCode}  // "---"
            ]
        );
    }
    &Output::print;
    &Log::debug("Finishing Entity::list_process sub");
    return 1;
}

=pod

=head1 list_events

=head2 PURPOSE



=head2 PARAMETERS

=over

=back

=head2 RETURNS

=head2 DESCRIPTION

=head2 THROWS

=head2 COMMENTS

=head2 SEE ALSO

=cut

sub list_events {
    &Log::debug("Starting entity::list_events sub");
    my $vmname = Opts::get_option('vmname');
    &Log::debug1("Opts are: vmname=>'$vmname'");
    my @titles = (qw(Username CreatedTime Datacenter Key ChainID Message));
    &Output::option_parser( \@titles );
    my $events = &VCenter::event_query($vmname);
    for my $event (@$events) {
        &Output::add_row(
            [
                $event->{userName} || "system",
                $event->{createdTime},
                $event->{datacenter}->{name},
                $event->{key},
                "'" . $event->{fullFormattedMessage} . "'"
            ]
        );
    }
    &Output::print;
    &Log::debug("Finishing entity::list_events sub");
    return 1;
}

=pod

=head2 change_altername

=head3 PURPOSE

Changes altername field to requested string

=head3 PARAMETERS

=over

=item vmname

Name of virtual Machine

=item name

String to change the alternate name

=back

=head3 RETURNS

True on success

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

=head3 TEST COVERAGE

Tested if altername changes the field

=cut

sub change_altername {
    &Log::debug("Starting Entity::change_altername sub");
    my $vmname = Opts::get_option('vmname');
    my $name   = Opts::get_option('name');
    &Log::debug1("Opts are: vmname=>'$vmname', name=>'$name'");
    &Guest::change_altername( $vmname, $name );
    &Log::debug("Finishing Entity::change_altername sub");
    return 1;
}

=pod

=head2 change_cdrom

=head3 PURPOSE

Changes the iso in a cdrom

=head3 PARAMETERS

=over

=item vmname

Name of virtual machine

=item num

Number of cdrom to change

=item iso

Datastore path to iso

=item unmount

Unmount the cdrom

=back

=head3 RETURNS

true on success

=head3 DESCRIPTION

=head3 THROWS

Vcenter::Opts if Opts are not expected
Vcenter::Path if Datastore path does not exist

=head3 COMMENTS

=head3 TEST COVERAGE

Tested if iso can be mounted, unmount works as expected
Also tested if exception is thrown if both not specified or both specified options, also if unknown file is requested to be mounted

=cut

sub change_cdrom {
    &Log::debug("Starting Entity::change_cdrom sub");
    my $vmname  = Opts::get_option('vmname');
    my $num     = Opts::get_option('num');
    my $iso     = Opts::get_option('iso') || 0;
    my $unmount = Opts::get_option('unmount') || 0;
    &Log::debug1(
"Opts are: vmname=>'$vmname', num=>'$num', iso=>'$iso', unmount=>'$unmount'"
    );
    if ( $unmount and $iso ) {
        Vcenter::Opts->throw(
            error => 'iso and unmount both specified',
            opt   => "unmount and iso"
        );
    }
    elsif ($unmount) {
        my $spec = &Guest::remove_cdrom_iso_spec( $vmname, $num );
        &Guest::reconfig_vm( $vmname, $spec );
    }
    elsif ($iso) {
        if ( &VCenter::datastore_file_exists($iso) ) {
            my $spec = &Guest::change_cdrom_iso_spec( $vmname, $num, $iso );
            &Guest::reconfig_vm( $vmname, $spec );
        }
        else {
            Vcenter::Path->throw(
                error => 'Datastore file could not be found',
                path  => $iso
            );
        }
    }
    else {
        Vcenter::Opts->throw(
            error => 'iso or unmount not specified',
            opt   => "unmount and iso"
        );
    }
    &Log::debug("Finishing Entity::change_cdrom sub");
    return 1;
}

=pod

=head2 change_interface

=head3 PURPOSE

Changes the interfaces network backing

=head3 PARAMETERS

=over

=item vmname

Name of virtual machine

=item num

Number of interface

=item network

Name of network on Vcenter

=back

=head3 RETURNS

True on success

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

=head3 TEST COVERAGE

Tested if Network interface can be changed

=cut

sub change_interface {
    &Log::debug("Starting Entity::change_interface sub");
    my $vmname  = Opts::get_option('vmname');
    my $num     = Opts::get_option('num');
    my $network = Opts::get_option('network');
    &Log::debug1(
        "Opts are: vmname=>'$vmname', num=>'$num', network=>'$network'");
    my $spec = &Guest::change_interface_spec( $vmname, $num, $network );
    &Guest::reconfig_vm( $vmname, $spec );
    &Log::debug("Finishing Entity::change_interface sub");
    return 1;
}

=pod

=head2 change_snapshot

=head3 PURPOSE

Changes the active snapshot to requested ID

=head3 PARAMETERS

=over

=item vmname

Name of virtual machine

=item id

Snapshot Id to revert to

=back

=head3 RETURNS

True on success

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

=head3 TEST COVERAGE

Tested if revert to requested id works

=cut

sub change_snapshot {
    &Log::debug("Starting Entity::change_snapshot sub");
    my $vmname = Opts::get_option('vmname');
    my $id     = Opts::get_option('id');
    &Log::debug1("Opts are: vmname=>'$vmname', id=>'$id'");
    &Guest::revert_to_snapshot( $vmname, $id );
    &Log::debug("Finishing Entity::change_snapshot sub");
    return 1;
}

=pod

=head2 add_snapshot

=head3 PURPOSE

Creates a snapshot for a machine

=head3 PARAMETERS

=over

=item vmname

Name of virtual machine

=item snap_name

Name of requested snapshot

=item desc

Description of snapshot

=back

=head3 RETURNS

True on success

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

=head3 TEST COVERAGE

Tested if snapshot can be created with call

=cut

sub add_snapshot {
    &Log::debug("Starting Entity::add_snapshot sub");
    my $vmname    = Opts::get_option('vmname');
    my $snap_name = Opts::get_option('snap_name');
    my $desc      = Opts::get_option('desc');
    &Log::debug1( "Opts are: vmname=>'"
          . $vmname
          . "', snap_name=>'"
          . $snap_name
          . "', desc=>'"
          . $desc
          . "'" );
    &Guest::create_snapshot( $vmname, $snap_name, $desc );
    &Log::info("Finishing Entity::add_snapshot sub");
    return 1;
}

=pod

=head2 add_interface

=head3 PURPOSE

Adds another interface to the requested virtual machine

=head3 PARAMETERS

=over

=item vmname

Name of Virtual machine

=item type

Type of interface to add

=back

=head3 RETURNS

True on success

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

=head3 TEST COVERAGE

Tested if VMXNET or E1000 can be added to all templates

=cut

sub add_interface {
    &Log::debug("Starting Entity::add_interface sub");
    my $vmname = Opts::get_option('vmname');
    my $type   = Opts::get_option('type');
    &Log::debug1("Opts are: vmname=>'$vmname'");
    my $spec = &Guest::add_interface_spec( $vmname, $type );
    &Guest::reconfig_vm( $vmname, $spec );
    &Log::info("Finishing Entity::add_interface sub");
    return 1;
}

=pod

=head2 add_cdrom

=head3 PURPOSE

Adds a ide cdrom to a virtual machine

=head3 PARAMETERS

=over

=item vmname

Name of virtual machine

=back

=head3 RETURNS

true on success

=head3 DESCRIPTION

Only one type of ide cdrom can be added to each machine. each template has 2 ide controllers and each controller can have 2 devices

=head3 THROWS

=head3 COMMENTS

=head3 TEST COVERAGE

tested if 4 ide cdroms can be added to vm. the 4 th add will throw an exception

=cut

sub add_cdrom {
    &Log::debug("Starting Entity::add_cdrom sub");
    my $vmname = Opts::get_option('vmname');
    &Log::debug1("Opts are: vmname=>'$vmname'");
    my $spec = &Guest::add_cdrom_spec($vmname);
    &Guest::reconfig_vm( $vmname, $spec );
    &Log::info("Finishing Entity::add_cdrom sub");
    return 1;
}

=pod

=head2 add_disk

=head3 PURPOSE

Adds a SCSI disk with requested size to vm

=head3 PARAMETERS

=over

=item vmname

Name of virtual machine

=item size

Size of requested disk in GB

=back

=head3 RETURNS

True on success

=head3 DESCRIPTION

A SCSI controller can have 15 devices. IN vmware ID 7 is used for the controller, and the last possible ID is 15

=head3 THROWS

=head3 COMMENTS

=head3 TEST COVERAGE

Tested if 14 disk can be added to vm. Exception is also tested

=cut

sub add_disk {
    &Log::debug("Starting Entity::add_cdrom sub");
    my $vmname = Opts::get_option('vmname');
    my $size   = Opts::get_option('size') * 1024;
    &Log::debug1("Opts are: vmname=>'$vmname', size=>'$size'");
    my $spec = &Guest::add_disk_spec( $vmname, $size );
    &Guest::reconfig_vm( $vmname, $spec );
    &Log::info("Finishing Entity::add_cdrom sub");
    return 1;
}

=pod

=head2 clone_vm

=head3 PURPOSE

Clones a Virtual Machine

=head3 PARAMETERS

=over

=item os_tmp

The template to use for cloning

=item ticket

The ticket to attach to

=item memory

The memory amount to use, defaults  to templates amount

=item cpu

The number of cpu cores to add, defaults to templates amount

=item domain

If set to no then Win machines is added to SUPPORT workgroup, if given then to support domain

=item parent_pool

In which resourcepool should the ticket resource pool be provisioned

=back

=head3 RETURNS

True on success

=head3 DESCRIPTION

=head3 THROWS

Entity::Snapshot if no snapshots are defined by template

=head3 COMMENTS

=head3 TEST COVERAGE

tested if all templates can be cloned

=cut

sub clone_vm {
    &Log::debug("Starting Entity::clone_vm sub");
    my $parent_pool = Opts::get_option('parent_pool');
    my $ticket      = Opts::get_option('ticket');
    my $os_temp     = Opts::get_option('os_temp');
    &Support::get_hash( 'template', $os_temp );
    my $domain = Opts::get_option('domain');
    &Log::debug1(
"Opts are: parent_pool=>'$parent_pool', ticket=>'$ticket', os_temp=>'$os_temp', domain=>'$domain'"
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
    print "Login: '"
      . &Support::get_key_value( 'template', $os_temp, 'username' ) . "'/'"
      . &Support::get_key_value( 'template', $os_temp, 'password' ) . "'\n";
    print "Unique name of vm: $vmname\n";
    my $altername = &Opts::get_option('altername');
    if ( $altername !~ /^$/ ) {
        &Log::debug("We need to change altername to '$altername'");
        &Guest::change_altername( $vmname, $altername );
    } else {
        &Log::debug("No change of altername is needed");
    }
    &Log::debug("Finishing Entity::clone_vm sub");
    return 1;
}

=pod

=head2 info_dumper

=head3 PURPOSE



=head3 PARAMETERS

=over

=back

=head3 RETURNS

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

=head3 TEST COVERAGE

=cut

sub info_dumper {
    &Log::debug("Starting Entity::info_dumper sub");
    my $vmname = Opts::get_option('vmname');
    &Log::debug1("Opts are: vmname=>'$vmname'");
    my $view = &Guest::entity_full_view( $vmname, 'VirtualMachine' );
    print Data::Dumper->Dump( [$view], ["view"] );
    &Log::debug("Finishing Entity::info_dumper sub");
    return 1;
}

=pod

=head2 info_runtime

=head3 PURPOSE



=head3 PARAMETERS

=over

=back

=head3 RETURNS

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

=head3 TEST COVERAGE

=cut

sub info_runtime {
    &Log::debug("Starting Entity::info_runtime sub");
    my $vmname = Opts::get_option('vmname');
    &Log::debug1("Opts are: vmname=>'$vmname'");
    my $view =
      &Guest::entity_property_view( $vmname, 'VirtualMachine', 'runtime' );
    print Data::Dumper->Dump( [$view], ["view"] );
    &Log::debug("Finishing Entity::info_runtime sub");
    return 1;
}

=pod

=head2 run_command

=head3 PURPOSE

Runs the requested program with arguments and env variables in guest

=head3 PARAMETERS

=over

=item vmname

Name of virtual machine

=item guestusername

Name of user to authenticate with in guest

=item guestpassword

Password of user to authenticate with in guest

=item env

Environmental variables to pass to program

=item workdir

Working directory to start program in

=item prog

Program to start

=item prog_arg

Arguments to hand the program

=back

=head3 RETURNS

True on success

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

=head3 TEST COVERAGE

Tested if a test program can be run in all tempaltes with VMware tools

=cut

sub run_command {
    &Log::debug("Starting Entity::run_command sub");
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
    &Log::debug("Finishing Entity::run_command sub");
    return 1;
}

=pod

=head2 transfer

=head3 PURPOSE



=head3 PARAMETERS

=over

=back

=head3 RETURNS

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

=head3 TEST COVERAGE

=cut

sub transfer {
    &Log::debug("Starting Entity::transfer sub");
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
        Vcenter::Opts->throw(
            error => 'Unrecognized opt given type,',
            opt   => $opts{type}
        );
    }
    &Log::debug("Finishing Entity::transfer sub");
    return 1;
}

=pod

=head1 delete_entity

=head2 PURPOSE

Deletes a requested entity

=head2 PARAMETERS

=over

=item name

Name of entity

=item type

Type of entity. Can be VirtualMachine/ResourcePool/Folder

=back

=head2 RETURNS

True on success

=head2 DESCRIPTION

=head2 THROWS

Entity::NumException if Entity is not empty or we could not delete the entity

=head2 COMMENTS

=head2 SEE ALSO

Tested if entity can be deleted with sub

=cut

sub delete_entity {
    &Log::debug("Starting Entity::delete_entity sub");
    my $name = Opts::get_option('name');
    my $type = Opts::get_option('type');
    &Log::debug1("Opts are: name=>'$name', type=>'$type'");
    if ( $type =~ /ResourcePool|Folder/ ) {
        if ( !&VCenter::check_if_empty_entity( $name, $type ) ) {
            Entity::NumException->throw(
                error  => "Entity $type is not empty",
                entity => $name,
                count  => "more"
            );
        }
    }
    elsif ( $type =~ /VirtualMachine/ ) {
        &Guest::poweroff($name);
    }
    &VCenter::destroy_entity( $name, $type );
    if ( &VCenter::exists_entity( $name, $type ) ) {
        Entity::NumException->throw(
            error  => '$type was not deleted succcesfully',
            entity => $name,
            count  => '1'
        );
    }
    &Log::info("Entity deleted succesfully");
    &Log::debug("Finishing Entity::delete_entity sub");
    return 1;
}

=pod

=head2 delete_snapshot

=head3 PURPOSE

Snapshot can be removed

=head3 PARAMETERS

=over

=item vmname

Name of virtual machine

=item id

Id of snapshot to remove

=item all

All snapshots should be removed

=back

=head3 RETURNS

True on success

=head3 DESCRIPTION

=head3 THROWS

Vcenter::Opts of id or all not given

=head3 COMMENTS

=head3 TEST COVERAGE

Tested if a single snapshot can be delete or all snapshots

=cut

sub delete_snapshot {
    &Log::debug("Starting Entity::delete_snapshot sub");
    my $vmname = Opts::get_option('vmname');
    my $id     = Opts::get_option('id') || 0;
    my $all    = Opts::get_option('all');
    &Log::debug("Opts are: vmname=>'$vmname', id=>'$id', all=>'$all'");
    if ($all) {
        &Log::debug("All snapshots need to be removed");
        &Guest::remove_all_snapshots($vmname);
    }
    elsif ($id) {
        &Log::debug("$id snapshot need to be removed");
        &Guest::remove_snapshot( $vmname, $id );
    }
    else {
        Vcenter::Opts->throw(
            error => "Either all or id needs to be given",
            opt   => "all or id"
        );
    }
    &Log::info("Finishing Entity::delete_snapshot sub");
    return 1;
}

=pod

=head1 delete_hw

=head2 PURPOSE

Deletes the requested hw

=head2 PARAMETERS

=over

=item vmname

Name of virtual machine

=item hw

Type of Hardware. Cane be interface/cdrom/disk

=item id

Number of hardware to delete. This can be returned from list sub

=back

=head2 RETURNS

True on success

=head2 DESCRIPTION

VCenter::Opts if unknown hw is requested to delete
Entity::HWError if no more hw to delete

=head2 THROWS

=head2 COMMENTS

=head2 TEST COVERAGE

Tested if exception is thrown if unknown hardware is requested
Tested if sub deletes all types of hardware and if HWError is thrown if no more hardware is possible or larges is requested

=cut

sub delete_hw {
    &Log::debug("Starting Entity::delete_hw sub");
    my $vmname = &Opts::get_option('vmname');
    my $id     = &Opts::get_option('id');
    my $hw     = &Opts::get_option('hw');
    if ( $hw eq "interface" ) {
        $hw = 'VirtualEthernetCard';
    }
    elsif ( $hw eq 'cdrom' ) {
        $hw = 'VirtualCdrom';
    }
    elsif ( $hw eq 'disk' ) {
        $hw = 'VirtualDisk';
    }
    else {
        Vcenter::Opts->throw(
            error => "Unknown HW requested to delete",
            opt   => $hw
        );
    }
    &Log::debug1("Opts are: vmname=>'$vmname', id=>'$id'");
    my @net_hw = @{ &Guest::get_hw( $vmname, $hw ) };
    if ( ( $id + 1 ) gt scalar(@net_hw) ) {
        Entity::HWError->throw(
            error  => "No more hardware to delete",
            entity => $vmname,
            hw     => $hw
        );
    }
    &Guest::remove_hw( $vmname, $net_hw[$id] );
    &Log::debug("Finishing Entity::delete_hw sub");
    return 1;
}

=pod

=head2 add_folder

=head3 PURPOSE



=head3 PARAMETERS

=over

=back

=head3 RETURNS

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

=head3 TEST COVERAGE

=cut

sub add_folder {
    &Log::debug("Starting Entity::add_folder sub");
    &VCenter::create_folder( &Opts::get_option('name'),
        &Opts::get_option('parent') );
    &Log::debug("Finishing Entity::add_folder sub");
    return 1;
}

=pod

=head2 add_resourcepool

=head3 PURPOSE



=head3 PARAMETERS

=over

=back

=head3 RETURNS

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

=head3 TEST COVERAGE

=cut

sub add_resourcepool {
    &Log::debug("Starting Entity::add_resourcepool sub");
    &VCenter::create_resource_pool( &Opts::get_option('name'),
        &Opts::get_option('parent') );
    &Log::debug("Finishing Entity::add_resourcepool sub");
    return 1;
}

=pod

=head2 promote

=head3 PURPOSE



=head3 PARAMETERS

=over

=back

=head3 RETURNS

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

=head3 TEST COVERAGE

=cut

sub promote {
    &Log::debug("Starting Entity::promote sub");
    my $vmname = &Opts::get_option('vmname');
    &Log::debug1("Opts are: vmname=>'$vmname'");
    &Guest::promote($vmname);
    &Log::debug("Finished Entity::promote sub");
    return 1;
}

=pod

=head1 change_power

=head2 PURPOSE

Changes powerstate of machine

=head2 PARAMETERS

=over

=item vmname

Name of virtual machine

=item state

State to change power to

=back

=head2 RETURNS

True on success

=head2 DESCRIPTION

=head2 THROWS

=head2 COMMENTS

=head2 TEST COVERAGE

=cut

sub change_power {
    &Log::debug("Starting entity::change_power sub");
    my $vmname = &Opts::get_option('vmname');
    my $state  = &Opts::get_option('state');
    if ( $state eq "on" ) {
        &Guest::poweron($vmname);
    }
    elsif ( $state eq "off" ) {
        &Guest::poweroff($vmname);
    }
    else {
        Vcenter::Opts->throw(
            error => "unknown option requested $state",
            opt   => $state
        );
    }
    &Log::debug("Finishing entity::change_power sub");
    return 1;
}

=pod

=head1 customization_status

=head2 PURPOSE



=head2 PARAMETERS

=over

=back

=head2 RETURNS

=head2 DESCRIPTION

=head2 THROWS

=head2 COMMENTS

=head2 SEE ALSO

=cut

sub customization_status {
    &Log::debug("Starting entity::customization_status sub");
    my $vmname = &Opts::get_option('vmname');
    my $time   = 1;
    if ( &Opts::get_option('wait') ) {
        $time = -1;
    }
    while ( $time ne 0 ) {
        my $status = &Guest::customization_status($vmname);
        if ( $status =~ /Finished|Failed/ ) {
            $time = 0;
        }
        else {
            sleep 5;
            $time--;
        }
        print $status . "\n";
    }
    &Log::debug("Finishing entity::customization_status sub");
    return 1;
}

=pod

=head2 list_templates

=head3 PURPOSE

List all usable templates

=head3 PARAMETERS

=over

=item output

Format of output. csv/table

=item noheader

Should header row be printed

=back

=head3 RETURNS

True on success

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

=head3 TEST COVERAGE

=cut

sub list_templates {
    &Log::debug("Starting Entity::list_templates sub");
    my $keys   = &Support::get_keys('template');
    my @titles = (qw(Name Path));
    &Output::option_parser( \@titles );
    for my $template (@$keys) {
        &Log::debug("Element working on:'$template'");
        my $path = &Support::get_key_value( 'template', $template, 'path' );
        &Output::add_row( [ $template, $path ] );
    }
    &Output::print;
    &Log::debug("Finishing Entity::list_templates sub");
    return 1;
}

1
