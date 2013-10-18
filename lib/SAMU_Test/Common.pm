use strict;
use warnings;

package Common;
use FindBin;
use lib "$FindBin::Bin/..";
use lib "$FindBin::Bin/../vmware_lib";
use BB::Common;
use Data::Dumper;

=pod

=head1 Common.pm

Collector sub for SAMU_TEST modules

=cut

use SAMU_Test::Test;

&Log::debug("Loaded module common");

our $VERSION = '1.0.0';

1
