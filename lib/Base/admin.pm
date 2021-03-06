package admin;

use strict;
use warnings;
use Base::misc;
use BB::Common;

my $help = 0;

=pod

=head1 admin.pm

Subroutines from Base/admin.pm

=cut

BEGIN {
    use Exporter();
    our ( @ISA, @EXPORT );

    @ISA    = qw(Exporter);
    @EXPORT = qw();
}

### subs

our $module_opts = {
    helper    => 'ADMIN',
    functions => {
        cleanup => {
            function        => \&cleanup,
            vcenter_connect => 1,
            opts            => {},
        },
        test => {
            function        => \&test,
            vcenter_connect => 1,
            opts            => {},
        },
        pod2wiki => {
            function        => \&pod2wiki,
            vcenter_connect => 0,
            prereq_module   => [qw(Pod::Simple::Wiki::Dokuwiki)],
            opts            => {
                in => {
                    type     => "=s",
                    help     => "Source Pod file",
                    required => 1,
                    default  => 0,
                },
                out => {
                    type     => "=s",
                    help     => "Output file",
                    required => 0,
                    default  => 0,
                },
                dokuserver => {
                    type     => "=s",
                    help     => "Dokuwiki XML RPC server url",
                    required => 0,
                    default => "https://supportwiki.balabit/lib/exe/xmlrpc.php",
                },
                dokuuser => {
                    type     => "=s",
                    help     => "Dokuwiki user, defaults to VCenter user",
                    required => 0,
                    default  => 0,
                },
                dokupass => {
                    type     => "=s",
                    help     => "Dokuwiki password, defaults to VCenter user",
                    required => 0,
                    default  => 0,
                },
                page => {
                    type     => "=s",
                    help     => "Pagename to upload to with namespace",
                    required => 0,
                    default  => 0,
                },
            },
        },
        list => {
            helper    => "ADMIN_functions/ADMIN_list_function",
            functions => {
                folder => {
                    function        => \&list_folder,
                    vcenter_connect => 1,
                    opts            => {
                        all => {
                            type     => "",
                            help     => "List all Folders",
                            required => 0,
                            default  => 0,
                        },
                        name => {
                            type     => "=s",
                            help     => "List a specific Folder",
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
                            default  => 0,
                        },
                    },
                },
                resourcepool => {
                    function        => \&list_resourcepool,
                    vcenter_connect => 1,
                    opts            => {
                        user => {
                            type     => "=s",
                            help     => "Which users resourcepool to list",
                            required => 0,
                            default  => 0,
                        },
                        all => {
                            type     => "",
                            help     => "List all resourcepools",
                            required => 0,
                            default  => 0,
                        },
                        name => {
                            type     => "=s",
                            help     => "List a specific resourcepool",
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
                            default  => 0,
                        },
                    },
                },
                linked_clones => {
                    function        => \&list_linked_clones,
                    vcenter_connect => 1,
                    opts            => {
                        template => {
                            type     => "=s",
                            help     => "Which templates linked clones to list",
                            required => 1,
                            default  => 0,
                        },
                    },
                },
                vms => {
                    function        => \&list_vms,
                    vcenter_connect => 1,
                    opts            => {
                        name => {
                            type     => "=s",
                            help     => "Name of user to list virtual machines",
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
                            default  => 0,
                        },
                        all => {
                            type     => "",
                            help     => "List all virtualmachines",
                            required => 0,
                            default  => 0,
                        },
                        vm => {
                            type => "=s",
                            help => "List information for one virtual machine",
                            required => 0,
                            default  => 0,
                        },
                    },
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

This is main entry point for Admin module

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
    &Log::debug("Starting Admin::main sub");
    &misc::option_parser( $module_opts, "main" );
    &Log::debug("Finishing Admin::main sub");
    return 1;
}

=pod

=head2 cleanup

=head3 PURPOSE

This sub cleans up orphaned entites on the VCenter

=head3 PARAMETERS

=over

=back

=head3 RETURNS

True on success

=head3 DESCRIPTION

Resourcepool, Folder and DistributedVirtualSwitch are tested to see if it has any children

=head3 THROWS

=head3 COMMENTS

=head3 TEST COVERAGE

Tested if cleans up empty ResourcePool, Folder, Switch
Tested if entity is defined on these views then it is left alone

=cut

sub cleanup {
    &Log::debug("Starting Admin::cleanup sub");
    my @types = ( 'ResourcePool', 'Folder', 'DistributedVirtualSwitch' );
    for my $type (@types) {
        &Log::info("Looping through $type");
        my $entities =
          Vim::find_entity_views( view_type => $type, properties => ['name'] );
        foreach my $entity (@$entities) {
            &Log::debug( "Checking " . $entity->name . " in $type" );
            &Log::dumpobj( "entity", $entity );
            if ( &VCenter::check_if_empty_entity( $entity->name, $type ) ) {
                &Log::info( "Deleting entity=>'"
                      . $entity->name
                      . "',type=>'"
                      . $type
                      . "'" );
                &VCenter::destroy_entity( $entity->name, $type );
            }
            else {
                &Log::info( "Entity has children " . $entity->name );
            }
        }
    }
    &Log::debug("Finishing Admin::cleanup sub");
    return 1;
}

=pod

=head2 test

=head3 PURPOSE

Sub is for testing correct functionality to VCenter

=head3 PARAMETERS

=over

=back

=head3 RETURNS

True on success

=head3 DESCRIPTION

The function only prints the current time on VCenter

=head3 THROWS

=head3 COMMENTS

=head3 TEST COVERAGE

Tested if valid time is returned

=cut

sub test {
    &Log::debug("Starting Admin::test sub");
    my $si_moref = ManagedObjectReference->new(
        type  => 'ServiceInstance',
        value => 'ServiceInstance'
    );
    my $si_view = Vim::get_view( mo_ref => $si_moref );
    print "Server Time : " . $si_view->CurrentTime() . "\n";
    &Log::debug("Finishing Admin::test sub");
    return 1;
}

=pod

=head2 pod2wiki

=head3 PURPOSE

Converts pod information to Dokuwiki formatted file

=head3 PARAMETERS

=over

=item in

The file that contains pod information

=item out

The output file localtion

=item page

Dokuwiki path to upload file

=item dokuuser

The Dokuwiki username to use to log in

=item dokupass

The Dokuwiki password to use to log in

=item dokuserver

The Dokuwiki server to connect to

=back

=head3 RETURNS

True on success

=head3 DESCRIPTION

The function extracts all dokuwiki information from a file, and converts it to Dokuwiki formatted text

=head3 THROWS

Connection::Connect when files cannot be opened

=head3 COMMENTS

=head3 TEST COVERAGE

=cut

sub pod2wiki {
    &Log::debug("Starting Admin::pod2wiki sub");
    my $in   = Opts::get_option('in');
    my $out  = Opts::get_option('out') || 0;
    my $page = Opts::get_option('page') || 0;
    &Log::debug1("Opts are: in=>'$in', out=>'$out',page=>'$page'");
    my $converted = &Misc::pod2wiki($in);
    if ($out) {
        &Log::debug("Output file requested");
        open( my $OUT, ">", $out )
          or Connection::Connect->throw(
            error => "Couldn't open: $!",
            type  => 'file',
            dest  => $out
          );
        print $OUT $converted;
    }
    else {
        &Log::debug("No output file requested");
    }
    if ($page) {
        &Log::debug("Requested upload to Dokuwiki page=>'$page'");
        my $server = &Opts::get_option('dokuserver');
        my $dokuuser =
          &Opts::get_option('dokuuser') || &Opts::get_option('username');
        my $dokupass =
          &Opts::get_option('dokupass') || &Opts::get_option('password');
        &Dokuwiki::connect( $server, $dokuuser, $dokupass );
        my $req = RPC::XML::request->new(
            'wiki.putPage',
            RPC::XML::string->new($page),
            RPC::XML::string->new($converted)
        );
        my $ret = &Dokuwiki::request($req);
        if ($ret) {
            &Log::debug("Upload succesful");
        }
        else {
            Connection::Connect->throw(
                error => 'Could not upload to Dokuwiki',
                type  => 'Dokuwiki',
                dest  => $page
            );
        }
    }
    else {
        &Log::debug("No upload to dokuwiki requested");
    }
    &Log::debug("Finishing Admin::pod2wiki sub");
    return 1;
}

=pod

=head2 list_resourcepool

=head3 PURPOSE

List requested resourcepool information

=head3 PARAMETERS

=over

=item user

List user resourcepool

=item all

List all resourcepools

=item name

List a specific resourcepool

=back

=head3 RETURNS

True on success

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

=head3 TEST COVERAGE

=cut

sub list_resourcepool {
    &Log::debug("Starting Admin::list_resourcepool sub");
    my $user = &Opts::get_option('user') || &Opts::get_option('username');
    &Log::debug1("Opts are: user=>'$user'");
    my @titles = (
        qw(ResourcePool VirtualMachineChilds ResourcePoolChilds Alarm Memory CPU MaxMemory MaxCPU)
    );
    &Output::option_parser( \@titles );
    my @request = ();
    if ( &Opts::get_option('all') ) {
        &Log::debug("All resource pools requested");
        my $views = Vim::find_entity_views(
            view_type  => 'ResourcePool',
            properties => ['name']
        );
        foreach (@$views) {
            &Log::debug( "Pushing " . $_->name . " to array" );
            push( @request, $_->name );
        }
    }
    elsif ( &Opts::get_option('name') ) {
        &Log::debug("One resourcepool requested");
        push( @request, &Opts::get_option('name') );
    }
    else {
        &Log::debug("Agents own resourcepool requested");
        my $tickets = &Misc::user_ticket_list($user);
        for my $ticket ( keys %$tickets ) {
            &Log::debug("Pushing resourcepool $ticket to array");
            push( @request, $ticket );
        }
    }
    &Log::dumpobj( "request array", \@request );
    for my $resourcepool ( sort @request ) {
        &Output::add_row( &VCenter::resourcepool_info($resourcepool) );
    }
    &Output::print;
    &Log::debug("Finishing Admin::list_resourcepool sub");
    return 1;
}

=pod

=head2 list_folder

=head3 PURPOSE

List requested folders information

=head3 PARAMETERS

=over

=item all

List all inventory folders

=item name

List a specific folder

=back

=head3 RETURNS

True on success

=head3 DESCRIPTION

=head3 THROWS

=head3 COMMENTS

=head3 TEST COVERAGE

=cut

sub list_folder {
    &Log::debug("Starting Admin::list_folder sub");
    my @process_folders = ();
    if ( &Opts::get_option('all') ) {
        &Log::debug("All folders requested");
        my $vm_folder_view = Vim::find_entity_view(
            view_type  => 'Folder',
            properties => ['name'],
            filter     => { name => 'vm' }
        );
        my $vim_folders = Vim::find_entity_views(
            view_type    => 'Folder',
            begin_entity => $vm_folder_view,
            properties   => ['name']
        );
        foreach (@$vim_folders) {
            &Log::debug( "Pushing " . $_->name . " to array" );
            push( @process_folders, $_->name );
        }
    }
    elsif ( &Opts::get_option('name') ) {
        &Log::debug("One folder requested");
        push( @process_folders, &Opts::get_option('name') );
    }
    else {
        &Log::debug("No option requested running VMWare sdk help");
        &Opts::usage;
    }
    my @titles = (qw(Folder VirtualMachineChilds FolderChilds));
    &Output::option_parser( \@titles );
    for my $folder (@process_folders) {
        my $sorted = &VCenter::folder_info($folder);
        &Output::add_row(
            [
                $folder,
                join( "/", @{ $sorted->{VirtualMachine} } ),
                join( "/", @{ $sorted->{Folder} } )
            ]
        );
        &Output::add_row( [ "-----", "-----", "-----" ] );
    }
    &Output::print;
    &Log::debug("Finishing Admin::list_folder sub");
    return 1;
}

=pod

=head2 list_linked_clones

=head3 PURPOSE

List all linked clones to a template

=head3 PARAMETERS

=over

=item template

Name of template to list information about

=back

=head3 RETURNS

True on success

=head3 DESCRIPTION

List the vm names that are linked to the linked clone

=head3 THROWS

=head3 COMMENTS

=head3 TEST COVERAGE

=cut

sub list_linked_clones {
    &Log::debug("Starting Admin:list_linked_clones sub");
    my $name = &Opts::get_option('template');
    &Log::debug1("Opts are: name=>'$name'");
    my $vmname =
      &VCenter::path2name(
        &Support::get_key_value( 'template', $name, 'path' ) );
    my $snapshot_view = &VCenter::vm_last_snapshot_view($vmname);
    my $devices       = $snapshot_view->{'config'}->{'hardware'}->{'device'};
    my $disk;
    foreach my $device (@$devices) {
        &Log::dumpobj( "device", $device );
        if ( defined( $device->{'backing'}->{'fileName'} ) ) {
            &Log::debug("Found backing fileName");
            $disk = $device->{'backing'}->{'fileName'};
            &Log::debug("disk is '$disk'");
            last;
        }
        &Log::debug2("Device is not for harddrive");
    }
    my @vms = @{ &VCenter::find_vms_with_disk($disk) };
    print "Vms linked to $name\n";
    foreach (@vms) {
        ( $_ ne $vmname ) and print "$_\n";
    }
    &Log::debug("Finishing Admin::list_linked_clones sub");
    return 1;
}

=pod

=head1 list_user_vms

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

sub list_vms {
    &Log::debug("Starting admin::list_user_vms sub");
    my @vms;
    if ( &Opts::get_option('all') ) {
        @vms = @{&Misc::vm_list};
    }
    elsif ( &Opts::get_option('vm') ) {
        @vms = ( &Opts::get_option('vm') );
    }
    else {
        my $name = &Opts::get_option('name') || &Opts::get_option('username');
        @vms = @{ &Misc::user_vm_list($name) };
    }
    my @titles = (
        qw(VirtualMachine PowerState BootTime CleanPowerOff MaxCpuUsage CpuUsage MaxMemoryUsage MemoryUsage Alarm Uptime)
    );
    &Output::option_parser( \@titles );
    for my $vm (@vms) {
        &Log::debug1( "Iterating through=>'" . $vm . "'" );
        &Output::add_row( &Guest::vm_info($vm) );
    }
    &Output::print;
    &Log::debug("Finishing admin::list_user_vms sub");
    return 1;
}

1
