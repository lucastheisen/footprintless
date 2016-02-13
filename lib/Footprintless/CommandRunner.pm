use strict;
use warnings;

package Footprintless::CommandRunner;

use Carp;
use Log::Any;

my $logger = Log::Any->get_logger();

sub new {
    return bless({}, shift)->_init(@_);
}

sub _init {
    my ($self, @options) = @_;
    return $self;
}

sub _run {
    croak("must use an implementation class");
}

sub run {
    my ($self, @options) = @_;

    $self->{last_call} = {};

    $logger->debugf('running [%s]', $options[0]);
    my $exit_code = $self->_run(@options);
    $self->{last_call}{exit_code} = $exit_code;

    return $exit_code;
}

sub run_or_die {
    my ($self, $command, $runner_options) = @_;
    my $exit_code = $self->run($command, $runner_options);
    if ($exit_code) {
        croak("$exit_code: " . ($self->{last_call}{stderr}
            ? $self->{last_call}{stderr}
            : ''));
    }
    return $self->{last_call}{stdout};
}

1;
