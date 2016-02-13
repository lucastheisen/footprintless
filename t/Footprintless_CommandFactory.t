use strict;
use warnings;

eval {
    require Log::Any::Adapter;
    Log::Any::Adapter->set('Stdout', log_level => 'error');
};

use Test::More tests => 4;

BEGIN {use_ok('Footprintless::CommandFactory')}

use Footprintless::CommandFactory;
use Footprintless::Localhost;

my $factory = Footprintless::CommandFactory->new(
    default_ssh => 'ssh');

is($factory->tail_command('/silly'), 'tail -f /silly', 'tail silly');
is(
    $factory->tail_command('/silly',
        $factory->command_options(
            hostname => 'localhost'
        )
    ), 
    'tail -f /silly', 'localhost tail silly');
is(
    $factory->tail_command('/silly',
        $factory->command_options(
            hostname => 'foo'
        )
    ), 
    'ssh foo "tail -f /silly"', 'foo tail silly');
