use strict;
use warnings;

use Test::More tests => 10;

BEGIN {use_ok('Footprintless::CommandRunner::IPCRun3')}
BEGIN {use_ok('Footprintless::CommandRunner::IPCRun')}

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

sub message {
    my ($runner, $text) = @_;
    my ($runner_name) = ref($runner);
    $runner_name =~ /.*::([^:]*)$/;
    return "$1 $text";
}

my $logger = Log::Any->get_logger();

foreach my $command_runner (
    Footprintless::CommandRunner::IPCRun3->new(),
    Footprintless::CommandRunner::IPCRun->new()) {

    is($command_runner->run_or_die('echo hello'), "hello$/", 
        message($command_runner, 'echo hello'));

    eval {$command_runner->run_or_die('perl -e "print STDERR \"foo\";exit 42"')};
    like($@, qr/^42: foo/, message($command_runner, 'expected to die'));

    eval {
        my $out = $command_runner->run_or_die('perl -e "print \"bar\";exit 0"');
        is($out, 'bar', message($command_runner, 'run_or_die returns out'));
    };
    ok(!$@, message($command_runner, 'expected not to fail'));
}
