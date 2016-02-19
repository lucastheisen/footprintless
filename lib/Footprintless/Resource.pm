use strict;
use warnings;

package Footprintless::Resource;

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
