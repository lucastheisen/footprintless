use strict;
use warnings;

package Footprintless::CommandRunner;

sub new {
    return bless({}, shift)->_init(@_);
}

sub _init {
    my ($self, @options) = @_;
    return $self;
}

sub run {
    my ($self, $command, $runner_options) = @_;
    print("$command\n");
    return 0;
}

sub run_or_die {
    my ($self, $command, $runner_options) = @_;
    my $exit_code = $self->run($command, $runner_options);
    if ($exit_code) {
        croak('exit($exit_code)');
    }
}

1;
