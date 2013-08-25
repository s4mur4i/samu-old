package Support;

use strict;
use warnings;
use BB::Error;

BEGIN {
    use Exporter;
    our @ISA = qw( Exporter );
    our @EXPORT = qw( &template_keys &template_info );
}

=pod

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
    'win_2008_en_x64_sta' => { path => 'Support/vm/templates/Windows/2008/T_win_2008_en_x64_sta', username => 'Administrator', password => 'titkos', key => 'TM24T-X9RMF-VWXK6-X8JC9-BFGM2', os => 'win' },
    'deb_7.0.0_en_amd64_wheezy' => { path => 'Support/vm/templates/Linux/deb/T_deb_7.0.0_en_amd64_wheezy', username => 'root', password => 'titkos', os => 'other' },
    'deb_6.0.0_en_amd64_squeeze' => { path => 'Support/vm/templates/Linux/deb/T_deb_6.0.0_en_amd64_squeeze', username => 'root', password => 'titkos', os => 'other' },
    'win_2008r2_en_x64_sta' => { path => 'Support/vm/templates/Windows/2008/T_win_2008r2_en_x64_sta', username => 'Administrator', password => 'titkos', key => 'YC6KT-GKW9T-YTKYR-T4X34-R7VHC', os => 'win' },
    'win_2008r2_en_x64_stadeb' => { path => 'Support/vm/templates/Windows/2008/T_win_2008r2_en_x64_stadeb', username => 'Administrator', password => 'titkos', key => 'YC6KT-GKW9T-YTKYR-T4X34-R7VHC', os => 'win' },
    'win_2008r2_en_x64_ent' => { path => 'Support/vm/templates/Windows/2008/T_win_2008r2_en_x64_ent', username => 'Administrator', password => 'TitkoS12', key => '489J6-VHDMP-X63PK-3K798-CPX3Y', os => 'win' },
    'win_2008r2sp1_en_x64_sta' => { path => 'Support/vm/templates/Windows/2008/T_win_2008r2sp1_en_x64_sta', username => 'Administrator', password => 'TitkoS12', key => 'YC6KT-GKW9T-YTKYR-T4X34-R7VHC', os => 'win' },
    'cent_6.0_en_amd64_cent64' => { path => 'Support/vm/templates/Linux/cent/T_cent_6.0_en_amd64_cent64', username => 'root', password => 'titkos', os => 'other' },
    'cent_6.4_en_i386_cent64' => { path => 'Support/vm/templates/Linux/cent/T_cent_6.4_en_i386_cent64', username => 'root', password => 'titkos', os => 'other' },
    'cent_6.4_en_amd64_cent64' => { path => 'Support/vm/templates/Linux/cent/T_cent_6.4_en_amd64_cent64', username => 'root', password => 'titkos', os => 'other' },
    'oracle_5.6_en_x64_ent' => { path => 'Support/vm/templates/Linux/cent/T_oracle_5.6_en_x64_ent', username => 'root', password => 'titkos', os => 'other' },
    'ssb_302' => { path => 'Support/vm/templates/SSB/3.0/T_ssb_302',  username => 'root', password => 'titkos', os => 'ssb' },
);

sub template_keys {
    my @keys;
    for my $key ( keys %template_hash ) {
        push(@keys, $key);
    }
    return \@keys;
}

sub template_info($) {
    my ( $template ) =@_;
    if ( defined($template_hash{$template}) ) {
        return $template_hash{$template};
    } else {
        Template::Status->throw( error => 'Requested template was not found', template => $template );
    }
}

__END__
