use strict;
use warnings;

package Footprintless::CommandRunner::Exception;

# ABSTRACT: A base exception class for Footprintless::CommandRunner
# PODNAME: Footprintless::CommandRunner::Exception

use Term::ANSIColor;
use overload '""' => 'to_string';

sub new {
    return bless({}, shift)->_init(@_);
}

sub _init {
    my ($self, $command, $exit_code, $message, $stderr) = @_;

    $self->{command} = $command;
    $self->{exit_code} = $exit_code;
    $self->{message} = $message;
    $self->{stderr} = $stderr;
    $self->{trace} = [];

    return $self;
}

sub exit {
    my ($self, $verbose) = shift;
    print(STDERR colored(['red'], "[$self->{command}]"), " failed ($self->{exit_code})\n");
    print(STDERR $self) if ($verbose);
    exit $self->{exit_code};
}

sub get_command {
    return $_[0]->{command};
}

sub get_exit_code {
    return $_[0]->{exit_code};
}

sub get_message {
    return $_[0]->{message};
}

sub get_stderr {
    return $_[0]->{stderr};
}

sub get_trace {
    return $_[0]->{trace};
}

sub PROPAGATE {
    my ($self, $file, $line) = @_;
    push(@{$self->{trace}}, [$file, $line]);
}

sub to_string {
    my ($self) = @_;

    my @parts = ($self->{exit_code});
    push(@parts, ": $self->{message}") if ($self->{message});
    push(@parts, "\n****STDERR****\n$self->{stderr}\n****STDERR****")
        if ($self->{stderr});
    if (@{$self->{trace}}) {
        push(@parts, "\n****TRACE****");
        foreach my $stop (@{$self->{trace}}) {
            push(@parts, "$stop->[0]($stop->[1])");
        }
        push(@parts, "\n****TRACE****");
    }

    return join('', @parts);
}

1;
__END__
=head1 DESCRIPTION

An exception used by C<Footprintless::CommandRunner> to propagate 
information related to the reason a command failed.

=constructor new($command, $exit_code, $message, $stderr)

Creates a new C<Footprintless::CommandRunner::Exception> with the 
supplied information.

=attribute get_command()

Returns the command.

=attribute get_exit_code()

Returns the exit code.

=attribute get_message()

Returns the message.

=attribute get_stderr()

Returns the stderr.

=attribute get_trace()

Returns the stack trace when the command runner C<die>d.

=method exit()

Prints diagnostic information to C<STDERR> then exits with exit code.

=method to_string()

Returns a string representation of this exception.

=for Pod::Coverage PROPAGATE

=head1 SEE ALSO
Footprintless::CommandRunner
Footprintless
