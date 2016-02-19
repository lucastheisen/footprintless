use strict;
use warnings;

package Footprintless::Resource::Url;

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
