use strict;
use warnings;

package Footprintless::CommandRunner;

# ABSTRACT: A contract for an command runner
# PODNAME: Footprintless::CommandRunner

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

sub get_command {
    return $_[0]->{last_call}{command};
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

    $self->{last_call} = {command => $command};

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

__END__
=head1 DESCRIPTION

The I<abstract> base class for all command runners.  This class defines 
the contract that all command runners must adhere to.  Implementation 
classes should implement C<_run($command, %runner_options)>.

=constructor new(@args)

See implementation classes.

=attribute get_command()

Returns the last command run by this command runner.

=attribute get_exception()

Returns the message from C<die>, if the command runner died unexpectedly.

=attribute get_exit_code()

Returns the exit code from running the command.

=attribute get_stderr()

Returns the text written to C<STDERR>.  This will only be available if
the command was run without any C<err_???> options.  See 
L<run|/"run($command, @runner_options)"> for more details.

=attribute get_stdout()

Returns the text written to C<STDOUT>.  This will only be available if
the command was run without any C<out_???> options.  See 
L<run|/"run($command, @runner_options)"> for more details.

=method run($command, %runner_options)

Runs C<$command>.  The supported runner options are:

=over 4

=item err_callback

A sub that will be called once for each line written to C<STDERR>.  The
only argument to the sub will be C<$line>.

=item err_handle

A handle to use as C<STDERR> for the command.

=item in_handle

A handle to use as C<STDIN> for the command.

=item out_callback

A sub that will be called once for each line written to C<STDOUT>.  The
only argument to the sub will be C<$line>.

=item out_handle

A handle to use as C<STDOUT> for the command.

=back

=method run_or_die($command, %runner_options)

Calls L<run|/"run($command, @runner_options)"> and will die with an
L<Footprintless::CommandRunner::Exception> if the exit code is non-zero.

=head1 SEE ALSO

Footprintless::Command
Footprintless::CommandOptionsFactory
Footprintless::CommandRunner::Exception
Footprintless

