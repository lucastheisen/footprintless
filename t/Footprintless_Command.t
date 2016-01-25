use strict;
use warnings;

eval {
    require Log::Log4perl;
    Log::Log4perl->easy_init($Log::Log4perl::ERROR);
    $Log::Log4perl::ERROR if (0); # prevent used only once warning
};

use Test::More tests => 6;

BEGIN {use_ok('Footprintless::Command')}

use Data::Dumper;
use Footprintless::Command qw(
    command_options
    tail_command
);

is(tail_command('access_log'), 'tail -f access_log', 'tail access_log');
is(tail_command('access_log', command_options(sudo_username => 'apache')),
    'sudo -u apache tail -f access_log', 
    'tail access_log');
is(tail_command('access_log', command_options(sudo_username => 'apache', hostname => 'localhost')),
    'ssh localhost "sudo -u apache tail -f access_log"', 
    'tail access_log localhost');
is(tail_command('access_log', command_options(sudo_username => 'apache', hostname => 'foo')),
    'ssh foo "sudo -u apache tail -f access_log"', 
    'tail access_log foo');
is(tail_command('access_log', command_options(ssh => 'ssh -q', sudo_username => 'apache', hostname => 'foo')),
    'ssh -q foo "sudo -u apache tail -f access_log"', 
    'ssh -q tail access_log foo');
