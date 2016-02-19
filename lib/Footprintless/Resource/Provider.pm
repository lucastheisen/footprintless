use strict;
use warnings;

package Footprintless::Resource::Provider;

sub new {
    return bless({}, shift)->_init(@_);
}

sub download {
    my ($self, $resource, @options) = @_;

    my $ref = ref($resource);
    if (!$resource->isa('Footprintless::Resource')) {
        if ($ref) {
            croak("invalid resource [$ref]");
        }
        $resource = $self->resource($resource);
    }

    return $self->_download($resource, @options);
}

sub _download {
    my ($self, $resource, @options) = @_;
    croak(__PACKAGE__ . " does not support [$resource]");
}

sub _init {
    my ($self) = @_;
    return $self;
}

sub resource {
    my ($self, $spec) = @_;
    croak(__PACKAGE__ . " does not support [$spec]");
}

sub supports {
    my ($self, $spec) = @_;
    return 0;
}

1;
