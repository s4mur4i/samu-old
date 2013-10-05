package admin;

use strict;
use warnings;
use Base::misc;
use BB::Common;

my $help = 0;

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
            function => \&cleanup,
            opts     => {},
        },
        templates => {
            function => \&templates,
            opts     => {},
        },
        test => {
            function => \&test,
            opts     => {},
        },
        pod2wiki => {
            function      => \&pod2wiki,
            prereq_module => [qw(Pod::Simple::Wiki::Dokuwiki)],
            opts          => {
                in => {
                    type     => "=s",
                    help     => "Source Pod file",
                    required => 1,
                },
                out => {
                    type     => "=s",
                    help     => "Output file",
                    required => 1,
                },
            },
        },
        list => {
            helper    => "ADMIN/ADMIN_list_functions",
            functions => {
                folder => {
                    function => \&list_folder,
                    opts     => {
                        all => {
                            type     => "=s",
                            help     => "List all Folders",
                            required => 0,
                        },
                        name => {
                            type     => "=s",
                            help     => "List a specific Folder",
                            required => 0,
                        },

                    },
                },
                resourcepool => {
                    function => \&list_resourcepool,
                    opts     => {
                        user => {
                            type     => "=s",
                            help     => "Which users resourcepool to list",
                            required => 0,
                        },
                        all => {
                            type     => "=s",
                            help     => "List all resourcepools",
                            required => 0,
                        },
                        name => {
                            type     => "=s",
                            help     => "List a specific resourcepool",
                            required => 0,
                        },
                    },
                },
                linked_clones => {
                    function => \&list_linked_clones,
                    opts     => {
                        template => {
                            type     => "=s",
                            help     => "Which templates linked clones to list",
                            required => 1,
                        },
                    },
                },
            },
        },
    },
};

=pod

=head1 main

=head2 PURPOSE

This is main entry point for Admin module

=head2 PARAMETERS

=back

=over

=head2 RETURNS

=head2 DESCRIPTION

=head2 THROWS

=head2 COMMENTS

=head2 SEE ALSO

=cut

sub main {
    &Log::debug("Starting Admin::main sub");
    &misc::option_parser( $module_opts, "main" );
    &Log::debug("Finishing Admin::main sub");
    return 1;
}

=pod

=head1 cleanup

=head2 PURPOSE

This sub cleans up orphaned entites on the VCenter

=head2 PARAMETERS

=back

=over

=head2 RETURNS

True on success

=head2 DESCRIPTION

Resourcepool, Folder and DistributedVirtualSwitch are tested to see if it has any children

=head2 THROWS

=head2 COMMENTS

=head2 SEE ALSO

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

=head1 templates

=head2 PURPOSE

List all usable templates

=head2 PARAMETERS

=back

=over

=head2 RETURNS

True on success

=head2 DESCRIPTION

=head2 THROWS

=head2 COMMENTS

=head2 SEE ALSO

=cut

sub templates {
    &Log::debug("Starting Admin::templates sub");
    my $keys = &Support::get_keys('template');
    my $max  = &Misc::array_longest($keys);
    for my $template (@$keys) {
        &Log::debug("Element working on:'$template'");
        my $path = &Support::get_key_value( 'template', $template, 'path' );

        # FIXME create better formating table or other possibilities
        my $length = ( $max - length($template) ) + 1;
        print "Name:'$template'" . " " x $length . "Path:'$path'\n";
    }
    &Log::debug("Finishing Admin::templates sub");
    return 1;
}

=pod

=head1 test

=head2 PURPOSE

Sub is for testing correct functionality to VCenter

=head2 PARAMETERS

=back

=over

=head2 RETURNS

True on success

=head2 DESCRIPTION

The function only prints the current time on VCenter

=head2 THROWS

=head2 COMMENTS

=head2 SEE ALSO

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

=head1 pod2wiki

=head2 PURPOSE

Converts pod information to Dokuwiki formatted file

=head2 PARAMETERS

=back

=item in

The file that contains pod information

=item out

The output file localtion

=over

=head2 RETURNS

True on success

=head2 DESCRIPTION

The function extracts all dokuwiki information from a file, and converts it to Dokuwiki formatted text

=head2 THROWS

Connection::Connect when files cannot be opened

=head2 COMMENTS

=head2 SEE ALSO

=cut

sub pod2wiki {
    &Log::debug("Starting Admin::pod2wiki sub");
    my $in     = Opts::get_option('in');
    my $out    = Opts::get_option('out');
    my $parser = Pod::Simple::Wiki->new('dokuwiki');
    &Log::debug1("Opts are: in=>'$in', out=>'$out'");
    open( my $IN, "<", $in )
      or Connection::Connect->throw(
        error => "Couldn't open: $!",
        type  => 'file',
        dest  => $in
      );
    open( my $OUT, ">", $out )
      or Connection::Connect->throw(
        error => "Couldn't open: $!",
        type  => 'file',
        dest  => $out
      );
    $parser->output_fh($OUT);
    $parser->parse_file($IN);
    &Log::debug("Finishing Admin::pod2wiki sub");
    return 1;
}

=pod

=head1 list_resourcepool

=head2 PURPOSE

List requested resourcepool information

=head2 PARAMETERS

=back

=item user

List user resourcepool

=item all

List all resourcepools

=item name

List a specific resourcepool

=over

=head2 RETURNS

True on success

=head2 DESCRIPTION

=head2 THROWS

=head2 COMMENTS

=head2 SEE ALSO

=cut

sub list_resourcepool {
    &Log::debug("Starting Admin::list_resourcepool sub");
    my $user = &Opts::get_option('user') || &Opts::get_option('username');
    &Log::debug1("Opts are: user=>'$user'");
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
    ## FIXME: mit is szeretnenk itt latni
    # VM count, resource use, power status
    # Text table!!!!
    &Log::debug("Finishing Admin::list_resourcepool sub");
    return 1;
}

=pod

=head1 list_folder

=head2 PURPOSE

List requested folders information

=head2 PARAMETERS

=back

=item all

List all inventory folders

=item name

List a specific folder

=over

=head2 RETURNS

True on success

=head2 DESCRIPTION

=head2 THROWS

=head2 COMMENTS

=head2 SEE ALSO

=cut

sub list_folder {
    &Log::debug("Starting Admin::list_folder sub");
    my @folder = ();
    if ( &Opts::get_option('all') ) {
        &Log::debug("All folders requested");
        my $vm_folder_view = Vim::find_entity_view(
            view_type  => 'Folder',
            properties => ['name'],
            filter     => { name => 'vm' }
        );
        my $folders = Vim::find_entity_view(
            view_type    => 'Folder',
            begin_entity => $vm_folder_view,
            properties   => ['name']
        );
        foreach (@$folders) {
            &Log::debug( "Pushing " . $_->name . " to array" );
            push( @folder, $_->name );
        }
    }
    elsif ( &Opts::get_option('name') ) {
        &Log::debug("One folder requested");
        push( @folder, &Opts::get_option('name') );
    }
    else {
        &Log::debug("No option requested running VMWare sdk help");
        &Opts::usage;
    }
    ## FIXME: mit es hogy printelni ide
    &Log::debug("Finishing Admin::list_folder sub");
    return 1;
}

=pod

=head1 list_linked_clones

=head2 PURPOSE

List all linked clones to a template

=head2 PARAMETERS

=back

=item template

Name of template to list information about

=over

=head2 RETURNS

True on success

=head2 DESCRIPTION

List the vm names that are linked to the linked clone

=head2 THROWS

=head2 COMMENTS

=head2 SEE ALSO

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
        print "$_\n" unless $_ eq $vmname;
    }
    &Log::debug("Finishing Admin::list_linked_clones sub");
    return 1;
}

1
