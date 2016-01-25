use strict;
use warnings;

eval {
    require Log::Log4perl;
    Log::Log4perl->easy_init($Log::Log4perl::ERROR);
    $Log::Log4perl::ERROR if (0); # prevent used only once warning
};

use Test::More tests => 3;

BEGIN {use_ok('Footprintless')}

use Data::Dumper;
use Footprintless;
use File::Basename;
use File::Spec;

my $test_dir = dirname( File::Spec->rel2abs( $0 ) );

my ($fpl);

ok($fpl = 
    Footprintless->new(
        config_dirs => File::Spec->catdir(
            $test_dir, 'config/entities'), 
        config_properties_file => File::Spec->catfile(
            $test_dir, 'config/credentials.pl')
    ), 'load data/entities');

ok($fpl->get_config()->{dev}, 'root is dev');
