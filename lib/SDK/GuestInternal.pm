package GuestInternal;

use strict;
use warnings;
use Data::Dumper;
use LWP::UserAgent;
use LWP::Simple qw(!head);
use File::Basename;
use SDK::Error;

BEGIN {
	use Exporter;
	our @ISA = qw( Exporter );
	our @EXPORT = qw( &test &acquireGuestAuth &get_xcb_ha_interface &get_interface_info &find_root_snapshot &runCommandInGuest &transfer_from_guest &transfer_to_guest );
}

## Acquire Guest authentication information to authenticate through vmware tools
## Parameters:
##  gOpMgr: Vim::get_service_content()->guestOperationsManager
##  vmview: Entity view to vm
##  gu: guest username
##  gp: guest password
## Returns:
##  NamePasswordAuthentication Object for authentication

sub acquireGuestAuth {
	my ( $gOpMgr, $vmview, $gu, $gp ) = @_;
	Util::trace( 4, "Starting GuestInternal::acquireGuestAuth sub\n" );
	my $authMgr = Vim::get_view( mo_ref => $gOpMgr->authManager );
	my $guestAuth = NamePasswordAuthentication->new( username => $gu, password => $gp, interactiveSession => 'false' );
	eval {
		Util::trace( 2, "Validating guest credentials in " . $vmview->name . " ...\n" );
		$authMgr->ValidateCredentialsInGuest( vm => $vmview, auth => $guestAuth );
	};
	if( $@ ) {
		SDK::Error::Entity::Auth->throw( error => 'Could not aquire Guest authentication object', entity => $vmview->name, username => $gu, password => $gp );
	} else {
		Util::trace( 1, "Succesfully validated guest credentials!\n" );
	}
	Util::trace( 4, "Finishing GuestInternal::acquireGuestAuth sub\n" );
	return $guestAuth;
}

## Runs a command in the guest through vmware tools
## Parameters:
##  vmname: name of vm to run commands in
##  prog: program to run in guest
##  prog_arg: arguments to program to run
##  env: environment variables to pass to program
##  workdir: workdir to start program in
##  guestusername: guest username to authenticate with
##  guestpassword: guest password to authenticate with
## Returns:
##  pid: pid of task started

sub runCommandInGuest {
	my ( $vmname, $prog, $prog_arg, $env, $workdir, $guestusername, $guestpassword ) = @_;
	Util::trace( 4, "Starting GuestInternal::runCommandInGuest sub\n" );
	my $vm_view = Vim::find_entity_view( view_type => 'VirtualMachine', properties => [ 'name' ], filter => { name => $vmname } );
	if ( !defined( $vm_view ) ) {
		SDK::Error::Entity::NumException->throw( error => 'Cannot find VM', entity => $vmname, count => '0' );
	}
	if ( !defined( $guestusername ) and !defined( $guestpassword ) ) {
		( $guestusername, $guestpassword ) = &auth_info( $vmname );
	}
	if ( !defined( $guestusername ) || !defined( $guestpassword ) || !defined( $vm_view ) ) {
		SDK::Error::Entity::Auth->throw( error => 'Missing argument for authentication', entity => !defined( $vm_view ) ? '0' : '1', username => !defined( $guestusername ) ? '0' : '1' , password => !defined( $guestpassword ) ? '0' : '1' );
	}
	my $guestOpMgr = Vim::get_view( mo_ref => Vim::get_service_content()->guestOperationsManager );
	if ( !defined( $guestOpMgr ) ) {
		SDK::Error::Entity::ServiceContent->throw( error => 'Could not retrieve Operation Manager' );
	}
	my $guestCreds = &acquireGuestAuth( $guestOpMgr, $vm_view, $guestusername, $guestpassword );
	my $guestProcMan = Vim::get_view( mo_ref => $guestOpMgr->processManager );
	my $guestProgSpec = GuestProgramSpec->new( workingDirectory => $workdir, programPath=> $prog, arguments => $prog_arg, envVariables => [$env] );
	my $pid = $guestProcMan->StartProgramInGuest( vm => $vm_view, auth => $guestCreds, spec => $guestProgSpec );
	Util::trace( 4, "Finishing GuestInternal::runCommandInGuest sub\n" );
	return $pid;
}

## Returns HA interface information for XCB products
## Parameters:
##  machine_ref: object reference to machine
## Returns:
##  key: device hardware key for identifying in hardware list
##  unitnumber: unitnumber on controller
##  controllerkey: device controller key
##  mac: mac address used reconfigure would override it

sub get_xcb_ha_interface {
	my ( $machine_ref ) = @_;
	Util::trace( 4, "Starting GuestInternal::get_xcb_ha_interface sub\n" );
	my @keys;
	my @unitnumber;
	my @controllerkey;
	my @mac;
	foreach ( @{$machine_ref->config->hardware->device} ) {
		my $interface = $_;
		if ( !$interface->isa( 'VirtualE1000' ) ) {
			next;
		}
		push( @keys, $interface->key );
		push( @unitnumber, $interface->unitNumber );
		push( @controllerkey, $interface->controllerKey );
		push( @mac, $interface->macAddress );
	}
	if ( ( @keys lt 4 ) && ( @unitnumber lt 4 ) && ( @controllerkey lt 4 ) ) {
		Util::trace( 2, "Not enough interfaces\n" );
		exit 1;
	}
	Util::trace( 4, "Finishing GuestInternal::get_xcb_ha_interface sub\n" );
	return ( $keys[3], $unitnumber[3], $controllerkey[3], $mac[3] );
}

## Returns interface information of requested machine interface
## Parameters:
##  machine_ref: object reference to machine
##  interface: number of interface to return(vcenter side)
## Returns:
##  key: device hardware key for identifying in hardware list
##  unitnumber: unitnumber on controller
##  controllerkey: device controller key
##  mac: mac address used reconfigure would override it

sub get_interface_info {
	my ( $machine_ref, $interface ) = @_;
	Util::trace( 4, "Starting GuestInternal::get_interface_info sub, interface=>'$interface'\n" );
	my @keys;
	my @unitnumber;
	my @controllerkey;
	my @mac;
	foreach ( @{$machine_ref->config->hardware->device} ) {
		my $interface = $_;
		if ( !$interface->isa( 'VirtualE1000' ) ) {
			next;
		}
		push( @keys, $interface->key );
		push( @unitnumber, $interface->unitNumber );
		push( @controllerkey, $interface->controllerKey );
		push( @mac, $interface->macAddress );
	}
	## We need to increment interface count because of perl indexing
	my $increment = $interface +1;
	if ( ( @keys lt $increment ) && ( @unitnumber lt $increment ) && ( @controllerkey lt $increment ) ) {
		Util::trace( 2, "Not enough interfaces. Interface $interface was requested but only @keys interfaces\n" );
		SDK::Error::Entity::HWError->throw( error => "Requested interface cannot be found", entity => $machine_ref->name, hw=> 'Interface count' );
	}
	Util::trace( 4, "Finishing GuestInternal::get_interface_info sub\n" );
	return ( $keys[$interface], $unitnumber[$interface], $controllerkey[$interface], $mac[$interface] );
}

sub find_root_snapshot {
	my ( $snapshot ) = @_;
	Util::trace( 4, "Starting GuestInternal::find_root_snapshot sub\n" );
	if ( defined( $snapshot->[0]->{'childSnapshotList'} ) ) {
		&find_root_snapshot( $snapshot->[0]->{'childSnapshotList'} );
	} else {
		Util::trace( 4, "Finishing GuestInternal::find_root_snapshot sub\n" );
		return $snapshot;
	}
}

sub transfer_to_guest {
	my ( $vmname, $path, $dest, $overwrite, $guestusername, $guestpassword ) = @_;
	Util::trace( 4, "Starting GuestInternal::transfer_to_guest sub\n" );
	my $vm_view = Vim::find_entity_view( view_type => 'VirtualMachine', filter => { name => $vmname } );
	if ( !defined( $vm_view ) ) {
		SDK::Error::Entity::NumException->throw( error => 'Cannot find VM', entity => $vmname, count => '0' );
	}
	if ( !defined( $guestusername ) and !defined( $guestpassword ) ) {
		( $guestusername, $guestpassword ) = &auth_info( $vmname );
	}
	if ( !defined( $guestusername ) || !defined( $guestpassword ) || !defined( $vm_view ) ) {
		SDK::Error::Entity::Auth->throw( error => 'Missing argument for authentication', entity => !defined( $vm_view ) ? '0' : '1', username => !defined( $guestusername ) ? '0' : '1' , password => !defined( $guestpassword ) ? '0' : '1' );
	}
	my $guestOpMgr = Vim::get_view( mo_ref => Vim::get_service_content()->guestOperationsManager );
	if ( !defined( $guestOpMgr ) ) {
		SDK::Error::Entity::ServiceContent->throw( error => 'Could not retrieve Operation Manager' );
	}
	my $guestCreds = &GuestInternal::acquireGuestAuth( $guestOpMgr, $vm_view, $guestusername, $guestpassword );
	my $guestFileMan = Vim::get_view( mo_ref => $guestOpMgr->fileManager );
	### Fixme : maybe give some options possibility
	my $fileattr = GuestFileAttributes->new();
	my $size = -s $path;
	my $transferinfo;
	eval {
		$transferinfo = $guestFileMan->InitiateFileTransferToGuest( vm => $vm_view, auth => $guestCreds, guestFilePath => $dest, fileAttributes => $fileattr, fileSize => $size, overwrite => $overwrite );
	};
	if( $@ ) {
		SDK::Error::Entity::TransferError->throw( error => 'Could not retrieve Transfer information' );
	}
	Util::trace( 0, "Information about file:'$path'\n" );
	Util::trace( 0, "Size of file: $size bytes\n" );
	my $ua  = LWP::UserAgent->new();
	$ua->ssl_opts( verify_hostname => 0 );
	open( my $fh, "<$path" );
	my $content = do{ local $/; <$fh> } ;
	my $req = $ua->put( $transferinfo, Content => $content );
	if ( $req->is_success() ) {
		Util::trace( 4, "OK: ", $req->content ."\n" );
	} else {
		SDK::Error::Entity::TransferError->throw( error => $req->as_string );
	}
	Util::trace( 4, "Finishing GuestInternal::transfer_to_guest sub\n" );
}

sub transfer_from_guest {
	my ( $vmname, $path, $dest, $guestusername, $guestpassword ) = @_;
	Util::trace( 4, "Starting GuestInternal::transfer_from_guest sub\n" );
	my $vm_view = Vim::find_entity_view( view_type => 'VirtualMachine', properties => [ 'name' ], filter => { name => $vmname } );
        if ( !defined( $vm_view ) ) {
		SDK::Error::Entity::NumException->throw( error => 'Cannot find VM', entity => $vmname, count => '0' );
	}
	if ( !defined( $guestusername ) and !defined( $guestpassword ) ) {
		( $guestusername, $guestpassword ) = &auth_info( $vmname );
	}
	if ( !defined( $guestusername ) || !defined( $guestpassword ) || !defined( $vm_view ) ) {
		SDK::Error::Entity::Auth->throw( error => 'Missing argument for authentication', entity => !defined( $vm_view ) ? '0' : '1', username => !defined( $guestusername ) ? '0' : '1' , password => !defined( $guestpassword ) ? '0' : '1' );
	}
	my $guestOpMgr = Vim::get_view( mo_ref => Vim::get_service_content()->guestOperationsManager );
	if ( !defined( $guestOpMgr ) ) {
		SDK::Error::Entity::ServiceContent->throw( error => 'Could not retrieve Operation Manager' );
	}
	my $guestCreds = &GuestInternal::acquireGuestAuth( $guestOpMgr, $vm_view, $guestusername, $guestpassword );
	my $guestFileMan = Vim::get_view( mo_ref => $guestOpMgr->fileManager );
	my $transferinfo;
	eval {
		$transferinfo = $guestFileMan->InitiateFileTransferFromGuest(vm=>$vm_view, auth=>$guestCreds, guestFilePath=>$path);
	};
	if($@) {
		SDK::Error::Entity::TransferError->throw( error => 'Could not retrieve Transfer information' );
	}
	Util::trace( 0, "Information about file: $path \n" );
	Util::trace( 0, "Size: " . $transferinfo->size. " bytes\n" );
	Util::trace( 0, "modification Time: " . $transferinfo->attributes->modificationTime . " and access Time : " .$transferinfo->attributes->accessTime . "\n" );
	if ( !defined($dest) ) {
		my $basename = basename($path);
		my $content = get($transferinfo->url);
		open(my $fh, ">/tmp/$basename");
		print $fh "$content";
		close($fh);
	} else {
		Util::trace( 4, "Downloading file to: '$dest'\n" );
		my $status = getstore($transferinfo->url,$dest);
	}
	Util::trace( 4, "Finishing GuestInternal::transfer_from_guest sub\n" );
}

sub auth_info {
	my ( $vmname ) = @_;
	Util::trace( 4, "Starting GuestInternal::auth_info sub, vmname=>'$vmname'\n" );
	if ( $vmname =~ /^[^-]*-[^-]*-[^-]*-\d{3}$/ ) {
		my ( $os ) = $vmname =~ m/^[^-]*-[^-]*-([^-]*)-\d{3}$/ ;
		if ( defined( $Support::template_hash{$os} ) ) {
			my $guestusername = $Support::template_hash{$os}{'username'};
			my $guestpassword = $Support::template_hash{$os}{'password'};
			return ( $guestusername, $guestpassword );
		} else {
			Util::trace( 4, "Finishing GuestInternal::auth_info sub, Regex matched an OS, but no template found to it os=> '$os'\n" );
			return 1;
		}
	} else {
		Util::trace( 4, "Finishing GuestInternal::auth_info sub, Not Standard name\n" );
		return 1;
	}
}


## Functionailty test sub
sub test() {
	Util::trace( 4, "Starting GuestInternal::test sub\n" );
	Util::trace( 0, "GuestInternal module test sub\n" );
	Util::trace( 4, "Finishing GuestInternal::test sub\n" );
}

#### We need to end with success
1
