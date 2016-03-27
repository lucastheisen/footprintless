use strict;
use warnings;

package Footprintless::InvalidEntityException;

# ABSTRACT: An exception thrown when an entity is invalid for the context it is being used in
# PODNAME: Footprintless::InvalidEntityException

use Term::ANSIColor;
use overload '""' => 'to_string';

sub new {
    return bless({}, shift)->_init(@_);
}

sub _init {
    my ($self, $message, $coordinate) = @_;

    $self->{message} = $message;
    $self->{coordinate} = $coordinate;
    $self->{trace} = [];

    return $self;
}

sub get_coordinate {
    return $_[0]->{coordinate};
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

    my @parts = ("invalid entity at [$self->{coordinate}]: $self->{message}");
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

An exception for when an entity is invalid for the context it is being used in.

=constructor new($message, $coordinate)

Creates a new C<Footprintless::InvalidEntityException> with the 
supplied information.

=attribute get_coordinate()

Returns the coordinate.

=attribute get_message()

Returns the message.

=attribute get_trace()

Returns the stack trace when the command runner C<die>d.

=method to_string()

Returns a string representation of this exception.

=for Pod::Coverage PROPAGATE

=head1 SEE ALSO

Footprintless
