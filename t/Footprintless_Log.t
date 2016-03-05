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
    open(my $handle, '>', $file);
    print($handle "foo\n");
    close($handle);
    print("REMOVE ME: wrote to $file\n");

    my $pid = fork();
    if ($pid == 0) {
        $logger->debug("started child");
        open($handle, '>>', $file);
        foreach my $line ('foo', 'foo', 'foo', 'bar', 'foo') {
            print($handle "$line\n");
            usleep(250000);
        }
        close($handle);
        $logger->debug("finished child, now exit");
        exit();
    }

    $logger->debug("started parent");
    my ($out, $err);
    if (1) {
        print("REMOVE ME:WTF?\n");
    Footprintless::Log->new(
        Config::Entities->new({
            entity => {
                logs => {
                    foo => $file
                }
            }
        }),
        'logs.foo')
        ->follow(
            until => qr/^bar$/, 
            runner_options => {out_buffer => \$out, err_buffer => \$err});
    }
    else {
        use IPC::Run;
        eval {
            IPC::Run::run(
                ["tail",  "-f", $file], 
                '>', sub {
                    my ($line) = @_;
                    print("REMOVE ME: [$line]\n");
                    $out .= $line;
                    if ($line =~ /bar/) {
                        print("REMOVE ME: bar found, now die\n");
                        die("until found");
                    }
                },
                '2>', \*STDERR);
        };
        if ($@) {
            print("REMOVE ME: [$@]\n");
            die($@) unless ($@ =~ /^ack until found /);
        }
        
        $out = "foo\nfoo\nfoo\nfoo\nbar\n";
    }

    wait();

    print("REMOVE ME: wait complete\n");
    is($out, "foo\nfoo\nfoo\nfoo\nbar\n", 'until');
}

print("Done\n");
