use strict;
use warnings;

package Footprintless::CommandRunner::IPCRun3;

use parent qw(Footprintless::CommandRunner);

use Carp;
use IPC::Run3;
use Log::Any;

my $logger = Log::Any->get_logger();

sub _run3_options {
    my ($self, $runner_options) = @_;

    my $in = \undef;
    my $out = \$self->{last_call}{stdout};
    my $err = \$self->{last_call}{stderr};

    return ($in, $out, $err);
}

sub _run {
    my ($self, $command, $runner_options) = @_;
    run3($command, $self->_run3_options($runner_options));
    return $? >> 8;
}

1;
