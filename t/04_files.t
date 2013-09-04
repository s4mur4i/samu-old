use strict;
use warnings;
use 5.14.0;
use Test::More;
use Test::Files;
use FindBin;
use lib "$FindBin::Bin/../lib";

dir_only_contains_ok("$FindBin::Bin/../lib/VMware", [qw(VICommon.pm VICredStore.pm VIExt.pm VILib.pm VIM25Runtime.pm VIM25Stub.pm VIM2Runtime.pm VIM2Stub.pm VIMRuntime.pm VIRuntime.pm)], "VMware contains the Default modules only");
dir_only_contains_ok("$FindBin::Bin/../lib/BB", [qw(Common.pm Error.pm Guest.pm Log.pm Misc.pm Support.pm VCenter.pm)], "BB only contains the default modules");
dir_only_contains_ok("$FindBin::Bin/../lib/Base", [qw(admin.pm bugzilla.pm datastore.pm entity.pm kayako.pm misc.pm ticket.pm)], "Base only contains the default modules");
dir_contains_ok("$FindBin::Bin/../", [qw(herring.pl generate_perl_modules.sh TEST_PERL_MODULES.pl)], "Base only contains the default modules");
done_testing;
