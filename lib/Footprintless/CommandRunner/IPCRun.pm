use strict;
use warnings;

package Footprintless::CommandRunner::IPCRun;

use parent qw(Footprintless::CommandRunner);

use Carp;
use IPC::Run;
use Log::Any;

my $logger = Log::Any->get_logger();

sub _run_options {
    my ($self, $runner_options) = @_;
    my @timeout;
    if ($runner_options->{timeout}) {
        @timeout = (IPC::Run::timeout($runner_options->{timeout}));
    }

    my $in = \undef;
    my $out = \$self->{last_call}{stdout};
    my $err = \$self->{last_call}{stderr};

    return ('<', $in, '>', $out, '2>', $err, @timeout);
}

sub _run {
    my ($self, $command, @runner_options) = @_;
    IPC::Run::run(['sh', '-c', $command], 
        $self->_run_options(@runner_options));
    return $? >> 8;
}

1;
