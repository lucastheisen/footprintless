use strict;
use warnings;

use lib 't/lib';

use Footprintless;
use Footprintless::Util qw(
    dumper
);
use Test::More tests => 5;

BEGIN {use_ok('Footprintless::Plugin')}

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

my $footprintless = Footprintless->new(entities => {
        footprintless => {
            plugins => [
                'Footprintless::Test::EchoPlugin'
            ]
        },
        a => {
            b => {
                foo => 'bar'
            }
        }
    });
is($footprintless->echo('a.b')->echo('foo'), 'bar', 'foo echoed bar');
is($footprintless->plugins(), 1, 'one registered plugin');
is(ref(($footprintless->plugins())[0]), 'Footprintless::Test::EchoPlugin', 
    'echo plugin registered');
is((($footprintless->plugins())[0]->command_packages())[0],
    'Footprintless::Test::EchoPlugin::Command',
    'echo plugin command packages');
