use strict;
use warnings;

package Footprintless::CommandRunner;

use Carp;
use Footprintless::CommandRunner::Exception;
use Log::Any;

my $logger = Log::Any->get_logger();

sub new {
    return bless({}, shift)->_init(@_);
}

sub _init {
    my ($self, @options) = @_;
    return $self;
}

sub get_exception {
    return $_[0]->{last_call}{exception};
}

sub get_exit_code {
    return $_[0]->{last_call}{exit_code};
}

sub get_stderr {
    return $_[0]->{last_call}{stderr};
}

sub get_stdout {
    return $_[0]->{last_call}{stdout};
}

sub _run {
    croak("must use an implementation class");
}

sub run {
    my ($self, $command, @runner_options) = @_;

    $self->{last_call} = {};

    $logger->debugf('running [%s]', $command);
    $logger->tracef('with options %s', \@runner_options);
    my $exit_code;
    eval {
        $exit_code = $self->_run($command, @runner_options);
        $self->{last_call}{exit_code} = $exit_code;
    };
    if ($@) {
        $self->{last_call}{exception} = $@;
        $exit_code = -1;
    }
    return $exit_code;
}

sub run_or_die {
    my ($self, $command, @runner_options) = @_;
    my $exit_code = $self->run($command, @runner_options);
    if ($exit_code) {
        die(Footprintless::CommandRunner::Exception->new(
            $command,
            $exit_code, 
            $self->{last_call}{exception},
            $self->{last_call}{stderr}));
    }
    return $self->{last_call}{stdout};
}

1;
