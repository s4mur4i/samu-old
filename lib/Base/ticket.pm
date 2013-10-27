package ticket;

use strict;
use warnings;
use Base::misc;

my $help = 0;

=pod

=head1 ticket.pm

Subroutines from Base/ticket.pm

=cut

BEGIN {
    use Exporter();
    our ( @ISA, @EXPORT );

    @ISA    = qw(Exporter);
    @EXPORT = qw();
}

our $module_opts = {
    helper    => "TICKET",
    functions => {
        info => {
            function        => \&ticket_info,
            vcenter_connect => 1,
            opts            => {
                ticket => {
                    type     => "=s",
                    help     => "Ticket to list information about",
                    required => 1,
                    default => "",
                },
            },
        },
        list => {
            function        => \&ticket_list,
            vcenter_connect => 1,
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
                    default => 0,
                    required => 0,
                },
            },
        },
        on => {
            function        => \&ticket_on,
            vcenter_connect => 1,
            opts            => {
                ticket => {
                    type     => "=s",
                    help     => "Ticket to power on",
                    default => "",
                    required => 1,
                },
            },
        },
        off => {
            function        => \&ticket_off,
            vcenter_connect => 1,
            opts            => {
                ticket => {
                    type     => "=s",
                    help     => "Ticket to power off",
                    default => "",
                    required => 1,
                },
            },
        },
        delete => {
            function        => \&ticket_delete,
            vcenter_connect => 1,
            opts            => {
                ticket => {
                    type     => "=s",
                    help     => "Ticket to delete",
                    default => "",
                    required => 1,
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
    &Log::debug("Starting Ticket::main sub");
    &misc::option_parser( $module_opts, "main" );
    &Log::debug("Finishing Ticket::main sub");
    return 1;
}

=pod

=head2 ticket_delete

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

sub ticket_delete {
    &Log::debug("Starting Ticket::ticket_delete sub");
    my $ticket = Opts::get_option('ticket');
    &Log::debug1("Opts are: ticket=>'$ticket'");
    my $machines = &VCenter::ticket_vms_name($ticket);
    for my $vm (@$machines) {
        &Log::debug("Powering off VM if not already powered off");
        &Guest::poweroff($vm);
        &Log::debug( "Deleting vm '" . $vm . "'" );
        &VCenter::destroy_entity( $vm, 'VirtualMachine' );
    }
    for my $type (qw(ResourcePool Folder)) {
        &Log::debug( "Deleting type '" . $type . "'" );
        my $entities = Vim::find_entity_views(
            view_type  => $type,
            properties => ['name'],
            filter     => { name => qr/^$ticket/ }
        );
        for my $entity (@$entities) {
            &Log::debug(
                "Deleting entity " . $entity->name . " in type " . $type );
            &VCenter::destroy_entity( $entity->name, $type );
        }
    }
    my $switch_view = Vim::find_entity_view(
        view_type  => 'DistributedVirtualSwitch',
        properties => ['name'],
        filter     => { name => $ticket }
    );
    if ( defined($switch_view) ) {
        &Log::debug("Found switch for ticket, deleting");
        &VCenter::destroy_entity( $switch_view->name,
            'DistributedVirtualSwitch' );
    }
    else {
        &Log::debug("No switch present for ticket");
    }
    print "Ticket deleted succesfully\n";
    &Log::debug("Finishing Ticket::ticket_delete sub");
    return 1;
}

=pod

=head2 ticket_info

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

sub ticket_info {
    &Log::debug("Starting Ticket::ticket_info sub");
    my $ticket = Opts::get_option('ticket');
    &Log::debug1("Opts are: ticket=>'$ticket'");
    my $machines = &VCenter::ticket_vms_name($ticket);
    for my $vm (@$machines) {
        &Log::debug( "Getting information about '" . $vm . "'" );
        &Log::debug("Starting Guest::short_vm_info sub, name=>'$vm'");
        &VCenter::num_check( $vm, 'VirtualMachine' );
        my $view = Vim::find_entity_view(
            view_type  => 'VirtualMachine',
            properties => [ 'name', 'guest', 'summary.runtime.powerState' ],
            filter => { name => $vm }
        );
        print "VMname:'" . $view->name . "\n";
        my $powerState = $view->get_property('summary.runtime.powerState');
        print "\tPower State:'" . $powerState->val . "'\n";

        print "\tAlternate name: '"
          . &Guest::get_altername( $view->name ) . "'\n";
        if ( $view->guest->toolsStatus eq 'toolsNotInstalled' ) {
            print "\tTools not installed. Cannot extract some information\n";
        }
        else {
            if ( defined( $view->guest->net ) ) {
                foreach ( @{ $view->guest->net } ) {
                    my $string = "";
                    if ( defined( $_->ipAddress ) ) {
                        $string = "ipAddresses => [ "
                          . join( ", ", @{ $_->ipAddress } ) . " ]";
                    }
                    if ( defined( $_->network ) ) {
                        $string .= ", Network => '" . $_->network . "'";
                    }
                    if ( $string =~ /^$/ ) {
                        $string = "No network information could be extracted";
                    }
                    print "\t" . $string . "\n";
                }
                if ( defined( $view->guest->hostName ) ) {
                    print "\tHostname: '" . $view->guest->hostName . "'\n";
                }
            }
            else {
                print "\tNo network information available\n";
            }
        }
        my $vm_info = &Misc::vmname_splitter( $view->name );
        my $os;
        if ( $vm_info->{type} =~ /xcb/ ) {
            &Log::debug("Product is an XCB product");
            $os = "$vm_info->{family}_$vm_info->{version}";
        }
        elsif ( $vm_info->{type} ne 'unknown' ) {
            &Log::debug("Product is known");
            $os =
"$vm_info->{family}_$vm_info->{version}_$vm_info->{lang}_$vm_info->{arch}_$vm_info->{type}";
        }
        if ( $vm_info->{uniq} ne 'unknown' ) {
            if ( defined( &Support::get_hash( 'template', $os ) ) ) {
                print "\tDefault login : '"
                  . &Support::get_key_value( 'template', $os, 'username' )
                  . "' / '"
                  . &Support::get_key_value( 'template', $os, 'password' )
                  . "'\n";
            }
            else {
                print
"\tRegex matched an OS, but no template found to it os => '$os'\n";
            }
        }
        else {
            print "\tVmname not standard name => '$vm'\n";
        }
    }
    &Log::debug("Finishing Ticket::ticket_info sub");
    return 1;
}

=pod

=head2 ticket_on

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

sub ticket_on {
    &Log::debug("Starting Ticket::ticket_on sub");
    my $ticket = Opts::get_option('ticket');
    &Log::debug1("Opts are: ticket=>'$ticket'");
    my $machines = &VCenter::ticket_vms_name($ticket);
    for my $vm (@$machines) {
        print "Powering on '" . $vm . "'\n";
        &Guest::poweron($vm);
    }
    &Log::debug("Finishing Ticket::ticket_on sub");
    return 1;
}

=pod

=head2 ticket_off

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

sub ticket_off {
    &Log::debug("Starting Ticket::ticket_off sub");
    my $ticket = Opts::get_option('ticket');
    &Log::debug1("Opts are: ticket=>'$ticket'");
    my $machines = &VCenter::ticket_vms_name($ticket);
    for my $vm (@$machines) {
        print "Powering off '" . $vm . "'\n";
        &Guest::poweroff($vm);
    }
    &Log::debug("Finishing Ticket::ticket_off sub");
    return 1;
}

=pod

=head2 ticket_list

=head3 PURPOSE



=head3 PARAMETERS

=over

=item output

Type of output. Can be csv or table

=item noheader

Removes the header row

=back

=head3 RETURNS

True on success

=head3 DESCRIPTION

=head3 THROWS

Vcenter::Opts if unknown option passed

=head3 COMMENTS

=head3 TEST COVERAGE

=cut

sub ticket_list {
    &Log::debug("Starting Ticket::ticket_list sub");
    my $tickets = &Misc::ticket_list;
    &Log::debug("Finished collecting ticket list");
    &Kayako::connect_kayako();
    my @titles = (qw(Ticket Owner Status B-Ticket B-Status));
    &Output::option_parser( \@titles );
    for my $ticket ( sort { $a <=> $b } ( keys %{$tickets} ) ) {
        &Log::debug("Collecting information about ticket=>'$ticket'");
        if ( $ticket ne "" and $ticket ne "unknown" ) {
            my @string;
            push( @string, $ticket );
            push( @string, $$tickets{$ticket} );
            my $result = &Kayako::run_query( "select ticketstatustitle from swtickets where ticketid = '$ticket'");
            if ( defined($result) ) {
                push( @string, $$result{ticketstatustitle} );
                $result = &Kayako::run_query( "select fieldvalue from swcustomfieldvalues where typeid = '$ticket' and customfieldid = '25'");
                if ( defined($result) and $$result{fieldvalue} ne "" ) {
                    my @result = split( " ", $$result{fieldvalue} );
                    my $bugzilla_status;
                    my $bugzilla_ticket;
                    foreach (@result) {
                        if ( $_ ne "" ) {
                            my $id;
                            if ( $_ =~ /^\s*\d+\s*$/ ) {
                                $id = $_;
                            }
                            elsif ( $_ =~ /\?id=\d+/ ) {
                                ($id) = $_ =~ /id=(\d+)\D?/;
                            }
                            else {
                                $id = $_;
                            }
                            if ( !$bugzilla_ticket ) {
                                $bugzilla_ticket = $id;
                            }
                            else {
                                $bugzilla_ticket .= "/$id";
                            }
                            my $content = &Bugzilla::bugzilla_status($id);
                            if ( !$bugzilla_status ) {
                                $bugzilla_status = $content;
                            }
                            else {
                                $bugzilla_status .= "/$content";
                            }
                        }
                    }
                    push( @string, $bugzilla_ticket );
                    push( @string, $bugzilla_status );
                }
                else {
                    push( @string, "---" );
                    push( @string, "---" );
                }
            }
            &Output::add_row( \@string );
        }
        else {
            &Log::debug("Ticket name is empty or unknown");
        }
    }
    &Output::print;
    &Log::debug("Finished printing ticket information");
    &Kayako::disconnect_kayako();
    &Log::debug("Finishing Ticket::ticket_list sub");
    return 1;
}

1
