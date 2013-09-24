use strict;
use warnings;

package Common;
use FindBin;
use lib "$FindBin::Bin/../../vmware_lib";

#tested
use BB::Log;
use BB::Error;
use BB::VCenter;
use BB::Support;
use BB::Misc;
use BB::Guest;
use BB::Bugzilla;
use BB::Kayako;

use VMware::VIRuntime;

&Log::debug1("Loaded module common");

#tested
our $VERSION = '1.0.0';

1
