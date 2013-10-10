use strict;
use warnings;

package Common;
use FindBin;
use lib "$FindBin::Bin/../../vmware_lib";

=pod

=head1 Common.pm

Collector sub for BB modules

=cut

use BB::Log;
use BB::Error;
use BB::VCenter;
use BB::Support;
use BB::Misc;
use BB::Guest;
use BB::Bugzilla;
use BB::Kayako;

use VMware::VIRuntime;

&Log::debug("Loaded module common");

our $VERSION = '1.0.0';

1
