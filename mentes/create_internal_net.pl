my $vm = Opts::get_option('vmname');
my $req_ticket = Opts::get_option('ticket');
my @vm = split(',',$vm);
my $name;
foreach (@vm) {
	my $machine = Vim::find_entity_view(view_type=>'VirtualMachine', filter=> {name => $_});
	if (!defined($machine)) {
		Util::trace( 0, "Cannot find machine: $_" );
		next;
	}
	my ($ticket, $username, $family, $version, $lang, $arch, $type , $uniq) = &Misc::vmname_splitter($machine->name);
	if (defined($req_ticket)) {
		$ticket = $req_ticket;
	}
	if ( !defined($ticket)) {
		Util::trace( 0, "Could not parse name from VM, or no ticket information specified.\n" );
		next;
	}
	eval {
	if (!defined($name)) {
		$name = $ticket . "-int-" . &Misc::random_3digit;
		while (&GuestManagement::dvportgroup_status($name)) {
			$name = $ticket . "-int-" . &Misc::random_3digit;
		}
		&GuestManagement::create_dvportgroup($name,$ticket);
	}
	if ( $type eq "xcb" ) {
		&GuestManagement::change_network_interface($machine->name,1,$name);
	} else {
		&GuestManagement::change_network_interface($machine->name,0,$name);
	}
	};

