use strict;
use warnings;

package Footprintless::Resource::Url;

# ABSTRACT: A resource described by URL
# PODNAME: Footprintless::Resource::Url

use parent qw(Footprintless::Resource);

sub get_uri {
    return $_[0]->{uri};
}

sub _init {
    my ($self, $url) = @_;

    $self->{uri} = URI->new($url);
    $self->{uri} = $self->{uri}->abs('file://') 
        unless ($self->{uri}->has_recognized_scheme());

    $self->Footprintless::Resource::_init($self->{uri}->as_string());

    return $self;
}

1;
__END__
=constructor new($url)

Creates a new C<Footprintless::Resource::Url> for the supplied URL.

=attribute get_uri()

Returns the C<URI> object for the URL.

=attribute get_url()

Returns the URL for this resource.

=head1 SEE ALSO

Footprintless::Resource::UrlProvider
Footprintless::ResourceManager
Footprintless
URI
