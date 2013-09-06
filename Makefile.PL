
use strict;
use warnings;

use ExtUtils::MakeMaker;
WriteMakefile(
    "NAME"             => "Herring::Sex",
    "VERSION"          => "20130905",
    "MIN_PERL_VERSION" => '5.14.0',
    "LICENSE"          => "perl",
    "test"             => {
        TESTS => 't/*.t t/*/*.t',
    },
    TEST_REQUIRES => {
        'Test::DNS'       => 0,
        'Test::EOL'       => 0,
        'Test::Exception' => 0,
        'Test::Files'     => 0,
        'Test::Fixme'     => 0,
        'Test::More'      => 0,
        'Test::PerlTidy'  => 0,
        'Test::Pod'       => 0,
        'Test::PureASCII' => 0,
        'Test::Spelling'  => 0,
    },
    PREREQ_PM => {
        'Archive::Zip'     => 0,
        'Data::Dumper'     => 0,
        'Exception::Class' => 0,
        'File::Path'       => 0,
        'Getopt::Long'     => 0,
        'HTTP::Cookies'    => 0,
        'HTTP::Headers'    => 0,
        'HTTP::Request'    => 0,
        'HTTP::Response'   => 0,
        'LWP::ConnCache'   => 0,
        'LWP::UserAgent'   => 0,
        'Pod::Simple'      => 0,
        'Pod::Usage'       => 0,
        'Sys::Syslog'      => 0,
        'URI::Escape'      => 0,
        'URI::URL'         => 0,
        'XML::LibXML'      => 0,
        'Carp'             => 0,
        'Encode'           => 0,
        'Exporter'         => 0,
        'FindBin'          => 0,
        'Switch'           => 0,
        'DBD::mysql'       => 0,
        'Module::Load'     => 0,
    },
    PREREQ_FATAL => 1,
);
