use strict;
use warnings;

package Footprintless::Resource;

# ABSTRACT: A resource provided by a provider
# PODNAME: Footprintless::Resource

sub new {
    return bless({}, shift)->_init(@_);
}

sub _init {
    my ($self, $url) = @_;

    $self->{url} = $url;

    return $self;
}

sub get_url {
    return $_[0]->{url};
}

1;
__END__
=head1 DESCRIPTION

The I<abstract> base class for all resources.  The class defines the 
contract that all resources must adhere to.  Resources are not intended 
to be used directly.  Instead an instance of 
C<Footprintless::ResourceManager> should be initialized with an ordered
list of providers.  See L<Footprintless::ResourceManager> for usage.

=constructor new($url)

See implementation classes.

=attribute get_url()

Returns the URL for this resource.

=head1 SEE ALSO

Footprintless::ResourceManager
Footprintless::Resource::Provider
Footprintless
