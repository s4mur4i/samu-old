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
    @EXPORT = qw(&main);
}

### subs

=pod

=head1 ADMIN_MAIN

=head2 DESCRIPTION

    This is the main entry sub to the admin functions. All further functions can be reached from here

=cut

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
            function => \&pod2wiki,
            opts     => {
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
            helper => 'ADMIN/ADMIN_list_functions',
            functions => {
                folder => {
                    function => \&list_folder,
                    opts => {
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
                    opts => {
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
            },
        },
    },
};

sub main {
    &Log::debug("Admin::main sub started");
    &misc::option_parser( $module_opts, "main" );
}

#tested
sub cleanup {
    &Log::debug("Starting Admin::cleanup sub");
    my @types = ( 'ResourcePool', 'Folder', 'DistributedVirtualSwitch' );
    for my $type (@types) {
        &Log::info("Looping through $type");
        my $entities =
          Vim::find_entity_views( view_type => $type, properties => ['name'] );
        foreach my $entity (@$entities) {
            &Log::debug( "Checking " . $entity->name . " in $type" );
            if ( &VCenter::check_if_empty_entity( $entity->name, $type ) ) {
                &Log::info( "Deleting entity=>'"
                      . $entity->name
                      . "',type=>'"
                      . $type
                      . "'" );
                &VCenter::destroy_entity( $entity->name, $type );
            }
        }
    }
}

#tested
sub templates {
    &Log::debug("Admin::templates sub started");
    my $keys = &Support::get_keys('template');
    my $max  = &Misc::array_longest($keys);
    for my $template (@$keys) {
        &Log::debug("Element working on:'$template'");
        my $path = &Support::get_key_value( 'template', $template, 'path' );
        my $length = ( $max - length($template) ) + 1;
        print "Name:'$template'" . " " x $length . "Path:'$path'\n";
    }
}

#tested
sub test {
    &Log::debug("Admin::test started");
    my $si_moref = ManagedObjectReference->new(
        type  => 'ServiceInstance',
        value => 'ServiceInstance'
    );
    my $si_view = Vim::get_view( mo_ref => $si_moref );
    print "Server Time : " . $si_view->CurrentTime() . "\n";
}

sub pod2wiki {
    eval { require Pod::Simple::Wiki::Dokuwiki; };
    if ($@) {
        &Log::debug("Cannot load Wiki module!");
        die "Pina";
    }
    my $in     = Opts::get_option('in');
    my $out    = Opts::get_option('out');
    my $parser = Pod::Simple::Wiki->new('dokuwiki');
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
}

sub list_resourcepool {
    &Log::debug("Starting admin::list_resourcepool sub");
    my $user = &Opts::get_option('user') || &Opts::get_option('username');
    my @request = ();
    if ( &Opts::get_option('all')) {
        my $views = Vim::find_entity_views( view_type => 'ResourcePool', properties => ['name'] );
        foreach ( @$views ) {
            push( @request, $_->name);
        }
    } elsif ( &Opts::get_option('name') ) {
        push( @request, &Opts::get_option('name') );
    } else {
        my $tickets = &Misc::user_ticket_list( $user );
        for my $ticket ( keys %$tickets ) {
            push(@request, $ticket);
        }
    }
    ## FIXME: mit is szeretnenk itt latni
    # VM count, resource use, power status
    # Text table!!!!
}

sub list_folder {
    &Log::debug("Starting admin::list_folder sub");
    my @folder=();
    if ( &Opts::get_option('all')) {
        my $vm_folder_view = Vim::find_entity_view( view_type => 'Folder', properties => ['name'],filter => { name => 'vm'} );
        my $folders = Vim::find_entity_view( view_type => 'Folder', begin_entity => $vm_folder_view, properties => ['name']);
        foreach (@$folders) {
            push(@folder, $_->name);
        }
    } elsif (&Opts::get_option('name')) {
        push(@folder, &Opts::get_option('name'));
    } else {
        &Log::warning("No option requested");
        exit;
    }
    ## FIXME: mit es hogy printelni ide
}

1
__END__
