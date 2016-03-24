use strict;
use warnings;

package Footprintless::Resource::Maven;

# ABSTRACT: A resource described by Maven artifact
# PODNAME: Footprintless::Resource::Maven

use parent qw(Footprintless::Resource);

sub get_artifact {
    return $_[0]->{artifact};
}

sub _init {
    my ($self, $artifact) = @_;

    $self->Footprintless::Resource::_init($artifact->get_url());
    $self->{artifact} = $artifact;

    return $self;
}

1;
__END__
=constructor new($artifact)

Creates a new C<Footprintless::Resource::Maven> for the supplied 
artifact.

=attribute get_artifact()

Returns the C<Maven::Artifact> object for the resource.

=attribute get_url()

Returns the URL for this resource.

=head1 SEE ALSO

Footprintless::Resource::MavenProvider
Footprintless::ResourceManager
Footprintless
Maven::Artifact
