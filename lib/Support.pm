package Support;

use strict;
use warnings;
use Data::Dumper;

BEGIN {
	use Exporter;
	our @ISA = qw(Exporter);
	our @EXPORT = qw( &test &runCommandInGuest %template_hash %agents_hash );
	our @EXPORT_OK = qw( &test &runCommandInGuest %template_hash %agents_hash );
}

### Tempalte name cannot contain '-' since regexes will fail matching to the name. '_' should be used instead
our %template_hash = (
	'scb_300' => { path => 'Support/vm/templates/SCB/3.0/T_scb_300',  username => 'root', password => 'titkos', os=>'scb' },
	'scb_330' => { path => 'Support/vm/templates/SCB/3.3/T_scb_330',  username => 'root', password => 'titkos', os=>'scb' },
	'scb_341' => { path => 'Support/vm/templates/SCB/3.4/T_scb_341', username => 'root', password => 'titkos', os=>'scb' },
	'win_7_en_x64_pro' => { path => 'Support/vm/templates/Windows/7/T_win_7_en_x64_pro',username => 'admin', password => 'titkos', key=>'FJ82H-XT6CR-J8D7P-XQJJ2-GPDD4', os=>'win' },
	'win_7_en_x86_ent' => { path => 'Support/vm/templates/Windows/7/T_win_7_en_x86_ent',username => 'admin', password => 'titkos', key=>'33PXH-7Y6KF-2VJC9-XBBR8-HVTHH', os=>'win' },
	'win_2003_en_x64_ent' => { path => 'Support/vm/templates/Windows/2003/T_win_2003_en_x64_ent',username => 'Administrator', password => 'titkos', key=>'T7RC2-XJ6DF-TBJ3B-KRR6F-898YG', os=>'win' },
	'deb_7.0.0_en_amd64_wheezy' => {path => 'Support/vm/templates/Linux/deb/T_deb_7.0.0_en_amd64_wheezy', username => 'root', password => 'titkos', os => 'other' },
);

our %agents_hash = (
	's4mur4i' => { mac=>'02:01:20:' },
	'balage' => { mac=>'02:01:19:' },
	'adrienn' => { mac=>'02:01:12:' },
	'varnyu' => { mac=>'02:01:40:' },
);

sub test() {
	print "test\n";
}

### run a command in guest.
### Parameters:
### $vmname, $prog, $prog_arg, $env, $workdir, $guestusername, $guestpassword
###
sub runCommandInGuest {
	my ($vmname, $prog, $prog_arg, $env, $workdir, $guestusername, $guestpassword) = @_;
	print "Variables: prog => " .$prog. " and arg => ".$prog_arg. "\n";
	my $vm_view = Vim::find_entity_view(view_type=>'VirtualMachine',filter=>{name=>$vmname});
	if ( !(defined($guestusername)) || !defined($guestpassword)) {
		if ( $vmname =~ /^[^-]*-[^-]*-[^-]*-\d{3}$/ ) {
		  my ($os) = $vmname =~ m/^[^-]*-[^-]*-([^-]*)-\d{3}$/ ;
		  if ( defined($Support::template_hash{$os})) {
			$guestusername=$Support::template_hash{$os}{'username'};
			$guestpassword=$Support::template_hash{$os}{'password'};
		  } else {
			print "Regex matched an OS, but no template found to it os=> '$os'\n";
		  }
		}
	}
	print "username=> '$guestusername' password=> '$guestpassword' vmname=> '" . defined($vm_view) . "'\n";
	if ( (!defined($guestusername)) || (!defined($guestpassword)) || (!defined($vm_view)) ) {
		die("Cannot run. some paramter failed to be parsed or guessed... or both: username=> '$guestusername' password=> '$guestpassword' vmname=> '" . defined($vm_view) . "'");
	}
	my $guestOpMgr = Vim::get_view(mo_ref => Vim::get_service_content()->guestOperationsManager);
	my $guestCreds = &acquireGuestAuth($guestOpMgr,$vm_view,$guestusername,$guestpassword);
	my $guestProcMan = Vim::get_view(mo_ref => $guestOpMgr->processManager);
	my $guestProgSpec = GuestProgramSpec->new(workingDirectory=> $workdir, programPath=> $prog, arguments => $prog_arg, envVariables =>[$env]);
	print Dumper($guestProgSpec);
	my $pid;
	eval {
		$pid = $guestProcMan->StartProgramInGuest(vm=>$vm_view, auth=>$guestCreds, spec=>$guestProgSpec);
	};
	if($@) {
			print Dumper($@);
			die( "Error: " . $@);
	}
}

sub acquireGuestAuth {
        my ($gOpMgr,$vmview,$gu,$gp) = @_;

        my $authMgr = Vim::get_view(mo_ref => $gOpMgr->authManager);
        my $guestAuth = NamePasswordAuthentication->new(username => $gu, password => $gp, interactiveSession => 'false');

        eval {
                print "Validating guest credentials in " . $vmview->name . " ...\n";
                $authMgr->ValidateCredentialsInGuest(vm => $vmview, auth => $guestAuth);
        };
        if($@) {
                die( "Error: " . $@ . "\n");
		print Dumper($@);
        } else {
                print "Succesfully validated guest credentials!\n";
        }

        return $guestAuth;
}

#### We need to end with success
1
