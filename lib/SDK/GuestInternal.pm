package GuestInternal;

use strict;
use warnings;
use Data::Dumper;
use LWP::UserAgent;
use LWP::Simple qw(!head);
use File::Basename;

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

	my $authMgr = Vim::get_view( mo_ref => $gOpMgr->authManager );
	my $guestAuth = NamePasswordAuthentication->new( username => $gu, password => $gp, interactiveSession => 'false' );

	eval {
		print "Validating guest credentials in " . $vmview->name . " ...\n";
		$authMgr->ValidateCredentialsInGuest( vm => $vmview, auth => $guestAuth );
	};
	if( $@ ) {
		die( "Error: " . $@ . "\n");
		print Dumper( $@ );
	} else {
		print "Succesfully validated guest credentials!\n";
	}

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
	my $vm_view = Vim::find_entity_view( view_type => 'VirtualMachine', filter => { name => $vmname } );
	if ( !defined( $guestusername ) and !defined( $guestpassword ) ) {
		( $guestusername, $guestpassword ) = &auth_info( $vmname );
	}
	if ( !defined( $guestusername ) || !defined( $guestpassword ) || !defined( $vm_view ) ) {
		return 1;
	}
	my $guestOpMgr = Vim::get_view( mo_ref => Vim::get_service_content()->guestOperationsManager );
	my $guestCreds = &acquireGuestAuth( $guestOpMgr, $vm_view, $guestusername, $guestpassword );
	my $guestProcMan = Vim::get_view( mo_ref => $guestOpMgr->processManager );
	my $guestProgSpec = GuestProgramSpec->new( workingDirectory => $workdir, programPath=> $prog, arguments => $prog_arg, envVariables => [$env] );
	my $pid = $guestProcMan->StartProgramInGuest( vm => $vm_view, auth => $guestCreds, spec => $guestProgSpec );
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
		print "Not enough interfaces.\n";
		exit 1;
	}
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
		print "Not enough interfaces. Interface $interface was requested but only @keys interfaces\n";
		exit 1;
	}
	return ( $keys[$interface], $unitnumber[$interface], $controllerkey[$interface], $mac[$interface] );
}

sub find_root_snapshot {
	my ( $snapshot ) = @_;
	if ( defined( $snapshot->[0]->{'childSnapshotList'} ) ) {
		&find_root_snapshot( $snapshot->[0]->{'childSnapshotList'} );
	} else {
		return $snapshot;
	}
}

sub transfer_to_guest {
	my ( $vmname, $path, $dest, $overwrite, $guestusername, $guestpassword ) = @_;
	my $vm_view = Vim::find_entity_view( view_type => 'VirtualMachine', filter => { name => $vmname } );
	if ( !defined( $guestusername ) and !defined( $guestpassword ) ) {
		( $guestusername, $guestpassword ) = &auth_info( $vmname );
	}
	if ( !defined( $guestusername ) || !defined( $guestpassword ) || !defined( $vm_view ) ) {
		return 1;
	}
	my $guestOpMgr = Vim::get_view( mo_ref => Vim::get_service_content()->guestOperationsManager );
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
		die( "Error: " . $@ );
	}
	print "Information about file: $path \n";
	print "Size of file: $size bytes\n";
	my $ua  = LWP::UserAgent->new();
	$ua->ssl_opts( verify_hostname => 0 );
	open( my $fh, "<$path" );
	my $content = do{ local $/; <$fh> } ;
	my $req = $ua->put( $transferinfo, Content => $content );
	if ( $req->is_success() ) {
		print "OK: ", $req->content ."\n";
	} else {
		print "Failed: ", $req->as_string . "\n";
	}
}

sub transfer_from_guest {
	my ( $vmname, $path, $dest, $guestusername, $guestpassword ) = @_;
	my $vm_view = Vim::find_entity_view( view_type => 'VirtualMachine', filter => { name => $vmname } );
	if ( !defined( $guestusername ) and !defined( $guestpassword ) ) {
		( $guestusername, $guestpassword ) = &auth_info( $vmname );
	}
	if ( !defined( $guestusername ) || !defined( $guestpassword ) || !defined( $vm_view ) ) {
		print "pina\n";
		return 1;
	}
	my $guestOpMgr = Vim::get_view( mo_ref => Vim::get_service_content()->guestOperationsManager );
	my $guestCreds = &GuestInternal::acquireGuestAuth( $guestOpMgr, $vm_view, $guestusername, $guestpassword );
	my $guestFileMan = Vim::get_view( mo_ref => $guestOpMgr->fileManager );
	my $transferinfo;
	eval {
		$transferinfo = $guestFileMan->InitiateFileTransferFromGuest(vm=>$vm_view, auth=>$guestCreds, guestFilePath=>$path);
	};
	if($@) {
		die( "Error: " . $@);
	}
	print "Information about file: $path \n";
	print "Size: " . $transferinfo->size. " bytes\n";
	print "modification Time: " . $transferinfo->attributes->modificationTime . " and access Time : " .$transferinfo->attributes->accessTime . "\n" ;
	if ( !defined($dest) ) {
		my $basename = basename($path);
		my $content = get($transferinfo->url);
		open(my $fh, ">/tmp/$basename");
		print $fh "$content";
		close($fh);
	} else {
		print Dumper($transferinfo);
		print "Downloading file to: '$dest'\n";
		my $status = getstore($transferinfo->url,$dest);
		print "My status is : $status\n";
	}
}

sub auth_info {
	my ( $vmname ) = @_;
	if ( $vmname =~ /^[^-]*-[^-]*-[^-]*-\d{3}$/ ) {
		my ( $os ) = $vmname =~ m/^[^-]*-[^-]*-([^-]*)-\d{3}$/ ;
		if ( defined( $Support::template_hash{$os} ) ) {
			my $guestusername = $Support::template_hash{$os}{'username'};
			my $guestpassword = $Support::template_hash{$os}{'password'};
			return ( $guestusername, $guestpassword );
		} else {
			print "Regex matched an OS, but no template found to it os=> '$os'\n";
			return 1;
		}
	} else {
		print "Not standard name.\n";
		return 1;
	}
}


## Functionailty test sub
sub test() {
	print "GuestInternal module test sub\n";
}

#### We need to end with success
1
