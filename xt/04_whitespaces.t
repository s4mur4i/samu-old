use strict;
use warnings;
use 5.14.0;
use FindBin;

use Test::Whitespaces{ dirs => ["$FindBin::Bin/../" ], ignore => [ qr{old/}, qr{VMware/}, qr{git} ] };
