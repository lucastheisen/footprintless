use strict;
use warnings;

eval {
    require Log::Log4perl;
    Log::Log4perl->easy_init($Log::Log4perl::ERROR);
    $Log::Log4perl::ERROR if (0); # prevent used only once warning
};
if ($@) {
}

use Test::More tests => 1;

BEGIN {use_ok('Footprintless')}

use Footprintless;

