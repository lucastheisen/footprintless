use strict;
use warnings;

eval {
    require Log::Any::Adapter;
    Log::Any::Adapter->set('Stdout', log_level => 'error');
};

use Test::More tests => 3;

BEGIN {use_ok('Footprintless')}

use Data::Dumper;
use Footprintless;
use File::Basename;
use File::Spec;
print("REMOVE ME: ", Dumper(\@INC), "\n");

my $test_dir = dirname( File::Spec->rel2abs( $0 ) );

my ($fpl);

ok($fpl = 
    Footprintless->new(
        config_dirs => File::Spec->catdir(
            $test_dir, 'config/entities'), 
        config_properties_file => File::Spec->catfile(
            $test_dir, 'config/credentials.pl')
    ), 'load data/entities');

ok($fpl->entities()->{dev}, 'root is dev');
