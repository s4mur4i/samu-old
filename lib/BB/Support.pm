package Support;

use strict;
use warnings;

BEGIN {
    use Exporter;
    our @ISA = qw( Exporter );
    our @EXPORT = qw( &get_keys &get_key_info &get_key_value );
}

=pod

=head1 template_hash

=head2 description

    This hash contains information about our templates.
=cut

my %template_hash = (
    'scb_300' => { path => 'Support/vm/templates/SCB/3.0/T_scb_300',  username => 'root', password => 'titkos', os => 'scb' },
    'scb_330' => { path => 'Support/vm/templates/SCB/3.3/T_scb_330',  username => 'root', password => 'titkos', os => 'scb' },
    'scb_341' => { path => 'Support/vm/templates/SCB/3.4/T_scb_341', username => 'root', password => 'titkos', os => 'scb' },
    'scb_342' => { path => 'Support/vm/templates/SCB/3.4/T_scb_342', username => 'root', password => 'titkos', os => 'scb' },
    'win_xpsp2_en_x64_pro' => { path => 'Support/vm/templates/Windows/xp/T_win_xpsp2_en_x64_pro', username => 'admin', password => 'titkos', key => 'T76MT-KCXJW-Y8J2V-PRQVQ-3B9WQ', os => 'win' },
    'win_7_en_x64_pro' => { path => 'Support/vm/templates/Windows/7/T_win_7_en_x64_pro', username => 'admin', password => 'titkos', key => 'FJ82H-XT6CR-J8D7P-XQJJ2-GPDD4', os => 'win' },
    'win_7_en_x86_ent' => { path => 'Support/vm/templates/Windows/7/T_win_7_en_x86_ent', username => 'admin', password => 'titkos', key => '33PXH-7Y6KF-2VJC9-XBBR8-HVTHH', os => 'win' },
    'win_2003_en_x64_ent' => { path => 'Support/vm/templates/Windows/2003/T_win_2003_en_x64_ent', username => 'Administrator', password => 'titkos', key => 'T7RC2-XJ6DF-TBJ3B-KRR6F-898YG', os => 'win' },
    'win_2008_en_x64_sta' => { path => 'Support/vm/templates/Windows/2008/T_win_2008_en_x64_sta', username => 'Administrator', password => 'TitkoS12', key => 'TM24T-X9RMF-VWXK6-X8JC9-BFGM2', os => 'win' },
    'deb_7.0.0_en_amd64_wheezy' => { path => 'Support/vm/templates/Linux/deb/T_deb_7.0.0_en_amd64_wheezy', username => 'root', password => 'titkos', os => 'other' },
    'deb_6.0.0_en_amd64_squeeze' => { path => 'Support/vm/templates/Linux/deb/T_deb_6.0.0_en_amd64_squeeze', username => 'root', password => 'titkos', os => 'other' },
    'win_2008r2_en_x64_sta' => { path => 'Support/vm/templates/Windows/2008/T_win_2008r2_en_x64_sta', username => 'Administrator', password => 'TitkoS12', key => 'YC6KT-GKW9T-YTKYR-T4X34-R7VHC', os => 'win' },
    'win_2008r2_en_x64_stadeb' => { path => 'Support/vm/templates/Windows/2008/T_win_2008r2_en_x64_stadeb', username => 'Administrator', password => 'TitkoS12', key => 'YC6KT-GKW9T-YTKYR-T4X34-R7VHC', os => 'win' },
    'win_2008r2_en_x64_ent' => { path => 'Support/vm/templates/Windows/2008/T_win_2008r2_en_x64_ent', username => 'Administrator', password => 'TitkoS12', key => '489J6-VHDMP-X63PK-3K798-CPX3Y', os => 'win' },
    'win_2008r2sp1_en_x64_sta' => { path => 'Support/vm/templates/Windows/2008/T_win_2008r2sp1_en_x64_sta', username => 'Administrator', password => 'TitkoS12', key => 'YC6KT-GKW9T-YTKYR-T4X34-R7VHC', os => 'win' },
    'cent_6.0_en_amd64_cent64' => { path => 'Support/vm/templates/Linux/cent/T_cent_6.0_en_amd64_cent64', username => 'root', password => 'titkos', os => 'other' },
    'cent_6.4_en_i386_cent64' => { path => 'Support/vm/templates/Linux/cent/T_cent_6.4_en_i386_cent64', username => 'root', password => 'titkos', os => 'other' },
    'cent_6.4_en_amd64_cent64' => { path => 'Support/vm/templates/Linux/cent/T_cent_6.4_en_amd64_cent64', username => 'root', password => 'titkos', os => 'other' },
    'oracle_5.6_en_x64_ent' => { path => 'Support/vm/templates/Linux/cent/T_oracle_5.6_en_x64_ent', username => 'root', password => 'titkos', os => 'other' },
    'ssb_302' => { path => 'Support/vm/templates/SSB/3.0/T_ssb_302',  username => 'root', password => 'titkos', os => 'ssb' },
);

my %agents_hash = (
    's4mur4i' => { mac => '02:01:20:' },
    'balage' => { mac => '02:01:12:' },
    'adrienn' => { mac => '02:01:19:' },
    'varnyu' => { mac => '02:01:19:' },
    'kkovari' => { mac => '02:01:00:' },
    'szaki' => { mac => '02:01:00:' },
    'blehel' => { mac => '02:01:00:' },
    'imre' => { mac => '02:01:00:' },
);

my %map_hash = (
    'agents' => \%agents_hash,
    'template' => \%template_hash,
);


=pod

=head2 template_keys

=head3 arguments

=head3 return

=head3 exception

=cut

sub get_keys($) {
    my ( $hash ) = @_;
    if ( defined $map_hash{$hash} ) {
        my $req_hash = $map_hash{$hash};
        return [keys %$req_hash];
    } else {
        Template::Status->throw( error => 'Requested hash_map was not found', template => $hash );
    }
}

=pod

=head2 get_key_info

=head3 arguments

=item template

=head3 return

=head3 exception

=cut

sub get_key_info($$) {
    my ( $hash, $key ) =@_;
    if ( grep/^$key$/, @{&get_keys($hash)} ) {
        return $map_hash{$hash}->{$key};
    } else {
        Template::Status->throw( error => 'Requested key info was not found', template => $key );
    }
}

sub get_key_value($$$) {
    my ( $hash, $key, $value ) = @_;
    my $key_hash = &get_key_info( $hash, $key );
    if ( defined($$key_hash{$value}) ) {
        return $$key_hash{$value};
    } else {
        Template::Status->throw( error => 'Requested key value was not found', template => $value );
    }
}

__END__
