
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
