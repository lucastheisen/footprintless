use strict;
use warnings;

package Footprintless::App::UsageException;

# ABSTRACT: An exception that indicates the invalid usage of a command
# PODNAME: Footprintless::App::UsageException

use Term::ANSIColor;
use overload '""' => 'to_string';

sub new {
    return bless({}, shift)->_init(@_);
}

sub _init {
    my ($self, $message, $coordinate) = @_;

    $self->{message} = $message;
    $self->{trace} = [];

    return $self;
}

sub get_message {
    return $_[0]->{message};
}

sub get_trace {
    return $_[0]->{trace};
}

sub PROPAGATE {
    my ($self, $file, $line) = @_;
    push(@{$self->{trace}}, [$file, $line]);
}

sub to_string {
    my ($self, $trace) = @_;

    my @parts = ($self->{message});
    if ($trace && @{$self->{trace}}) {
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

An exception that indicates the invalid usage of a command

=constructor new($message)

Creates a new C<Footprintless::App::UsageException> with the 
supplied information.

=attribute get_message()

Returns the message.

=attribute get_trace()

Returns the stack trace when the command runner C<die>d.

=method to_string()

Returns a string representation of this exception.

=for Pod::Coverage PROPAGATE

=head1 SEE ALSO

Footprintless
