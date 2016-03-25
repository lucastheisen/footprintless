use strict;
use warnings;

use lib 't/lib';

use Test::More tests => 7;
use Data::Dumper;
use Footprintless;
use File::Basename;
use File::Spec;

BEGIN {use_ok('Footprintless')}

eval {
    require Getopt::Long;
    Getopt::Long::Configure('pass_through', 'bundling');
    my $level = 'error';
    Getopt::Long::GetOptions(
        'log:s' => \$level
    );

    require Log::Any::Adapter;
    Log::Any::Adapter->set('Stdout', 
        log_level => Log::Any::Adapter::Util::numeric_level($level));
};

my $logger = Log::Any->get_logger();

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

ok($fpl = Footprintless->new(entities => {foo=>'bar'}),
    'entities hashref');
is($fpl->entities()->{foo}, 'bar', 'entities hashref foo is bar');

ok($fpl = Footprintless->new(entities => 
    Config::Entities->new({entity => {foo=>'bar'}})),
    'entities Config::Entities');
is($fpl->entities()->{foo}, 'bar', 'entities Config::Entities foo is bar');

