use strict;
use warnings;

package Footprintless::CommandRunner::IPCRun;

use parent qw(Footprintless::CommandRunner);

use Carp;
use IPC::Run qw(run);
use Log::Any;

my $logger = Log::Any->get_logger();

sub _run_options {
    my ($self, $runner_options) = @_;

    my $in = \undef;
    my $out = \$self->{last_call}{stdout};
    my $err = \$self->{last_call}{stderr};

    return ($in, $out, $err);
}

sub _run {
    my ($self, $command, $runner_options) = @_;
    run($command, $self->_run_options($runner_options));
use Data::Dumper;print("REMOVE ME: ", Dumper($?), "\n");
    return $? >> 8;
}

1;
