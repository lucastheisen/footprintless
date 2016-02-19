use strict;
use warnings;

package Footprintless::ResourceManager;

use Carp;
use Footprintless::Resource::Maven;
use Footprintless::Resource::Url;

sub new {
    return bless({}, shift)->_init(@_);
}

sub download {
    # download($resource, [%options])
    my ($self, $resource, @options) = @_;

    foreach my $provider (@{$self->{providers}}) {
        if ($provider->supports($resource)) {
            return $provider->download($resource, @options);
        }
    }

    croak("unsupported resource type [$resource]");
}

sub _init {
    my ($self, @providers) = @_;

    $self->{providers} = \@providers;
    
    return $self;
}

sub resource {
    # resource($spec)
    my ($self, $spec) = @_;

    foreach my $provider (@{$self->{providers}}) {
        if ($provider->supports($spec)) {
            return $provider->resource($spec);
        }
    }

    croak("unsupported resource: $spec");
}

1;
