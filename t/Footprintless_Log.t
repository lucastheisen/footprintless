use strict;
use warnings;

use lib 't/lib';

use Config::Entities;
use File::Basename;
use File::Spec;
use File::Temp;
use Footprintless::Localhost;
use Footprintless::Util qw(
    default_command_runner 
    dumper 
    slurp 
    spurt
);
use IO::Handle;
use Test::More tests => 2;
use Time::HiRes qw(usleep);

BEGIN {use_ok('Footprintless::Log')}

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
my $test_dir = dirname(File::Spec->rel2abs($0));

{
    my $file = File::Temp->new();
    my @expected = ('foo', 'foo', 'foo', 'bar');
    my $pid = fork();
    if ($pid == 0) {
        $logger->debug("started child");
        open(my $handle, '>>', $file);
        foreach my $line (@expected, 'foo') {
            print($handle "$line\n");
            usleep(250000);
        }
        close($handle);
        $logger->debug("finished child, now exit");
        exit();
    }

    $logger->debug("started parent");
    my (@out);
    Footprintless::Log->new(
        Config::Entities->new({
            entity => {
                logs => {
                    foo => $file
                }
            }
        }),
        'logs.foo')
        ->follow(until => qr/^bar$/, runner_options => {
            out_callback => sub {push(@out, @_)}
        });

    wait();

    is_deeply(\@out, \@expected, 'until');
}

print("Done\n");
