
## Generates a new mac and test if uniq
## Parameters:
##
## Returns:
##  mac: new mac address format: xx:xx:xx:xx:xx:xx

sub generate_uniq_mac {
	Util::trace( 4, "Starting Misc::generate_uniq_mac sub\n" );
	my $mac = &generate_mac;
	Util::trace( 1, "Generated mac address, mac=>'$mac'\n" );
	while ( &Vcenter::mac_compare( $mac ) ) {
		Util::trace( 1, "Found duplicate mac, need to regenerate\n" );
		$mac = &generate_mac;
		Util::trace( 1, "New generated mac address=>'$mac'\n" );
	}
	Util::trace( 4, "Finished Misc::generate_uniq_mac sub, mac=>'$mac'\n" );
	return $mac;
}

sub path_to_url {
	my ( $path ) = @_;
	Util::trace( 4, "Starting Misc::path_to_url sub, path=>'$path'\n" );
	my $url_base ="https://vcenter.ittest.balabit/folder/";
	my ( $datastore, $path_url ) = $path =~ /^\[([^\]]*)\]\s*(.*)$/;
	my $return = $url_base . $path_url ."?dcPath =Support&dsName =" .$datastore;
	$return =~ s/-/%2d/g;
	$return =~ s/\./%2e/g;
	Util::trace( 4, "Finished Misc::path_to_url sub, url=>'$return'\n" );
	return $return;
}
