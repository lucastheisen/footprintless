use strict;
use warnings;

package Footprintless::Resource;

sub new {
    return bless({}, shift)->_init(@_);
}

sub _init {
    my ($self, %spec) = @_;

    $self->{url} = $spec->{url};
    $self->{path} = $spec->{path};
    $self->{path_options} = $spec->{path_options};

    return $self;
}

1;
