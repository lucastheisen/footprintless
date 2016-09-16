use strict;
use warnings;

package Footprintless::MixableBase;

# ABSTRACT: A base class for using mixins
# PODNAME: Footprintless::MixableBase

use Log::Any;

my $logger = Log::Any->get_logger();

sub new {
    my ($class, $factory, $coordinate, @options) = @_;
    $logger->tracef("%s coordinate=[%s]\noptions=[%s]",
        $class, $coordinate, \@options );
    my $self = bless(
        {
            factory => $factory,
            coordinate => $coordinate
        },
        $class);

    return $self->_init(@options);
}

sub _init {
    return $_[0];
}

1;
__END__
=head1 SYNOPSIS

    package Foo;

    use parent qw(Footprintless::MixableBase)

    use Footprintless::Mixins qw(
        _sub_entity
        ...
    );

    sub _init {
        my ($self, %options);
        $self->{debug} = $options{debug};
        $self->{user} = $self->_entity('user', 1);
        return $self;
    }

    sub get_user {
        my ($self) = @_;
        print("getting user\n") if ($self->{debug});
        return $self->{user};
    }

    package main;

    use Footprintless::Util qw(factory);

    my $foo = Foo->new(
        factory({
            root => {
                foo => {
                    user => 'bar'
                }
            }
        }),
        'root.foo',
        debug => 1);

    my $user = $foo->get_user(); # returns 'bar'

=head1 DESCRIPTION

Provides the boilerplate constructor for packages that want to use
L<Footprintless::Mixins>.  Specifically, strips off the first two 
parameters (C<$factory> and C<$coordinate>) and sets them as member
variables (C<$self->{factory}> and C<$self->{coordinate}>).  Then it
passes on the remainder of the arguments to the C<_init> method.
Subclasses should override C<_init> for additional initialization.

=for Pod::Coverage new

=head1 SEE ALSO

Footprintless
Footprintless::Mixins
