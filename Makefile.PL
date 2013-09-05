
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    "NAME" => "Herring::Sex",
    "test" => {
        TESTS => 't/*.t',
    },
);
