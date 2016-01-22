use strict;
use warnings;

package Footprintless;

# ABSTRACT: A utility for managing systems with minimal installs
# PODNAME: Footprintless

use Carp;
use Log::Any;

my $logger = Log::Any->get_logger();

sub new {
    return bless( {}, shift )->_init( @_ );
}


sub _init {
    my ($self, $entity, %options) = @_;
    
    $logger->debug( 'creating new Footprintless' );

    $self->{resolver} = $options{resolver} || Template::Resolver->new();

    return $self;
}

1;

__END__
=head1 SYNOPSIS

  use Footprintless;

=head1 DESCRIPTION

This module ...

=constructor new(\%entity, %options)

Creates a new Footprintless agent.  Available options are:

=over 4

=item resolver

A preconfigured instance of Template::Resolver.  If not supplied, one
will be created with default configuration. 

=back

=method update($entity)

Will read from C<$file_handle_or_name> replacing all placeholders prefixed by 
C<$placeholder_prefix>.

=head1 SEE ALSO
Template::Resolver
https://github.com/lucastheisen/footprintless
