use strict;
use warnings;

package Footprintless::Resource::Maven;

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
