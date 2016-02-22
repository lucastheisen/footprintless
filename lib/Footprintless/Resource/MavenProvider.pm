use strict;
use warnings;

package Footprintless::Resource::MavenProvider;

use parent qw(Footprintless::Resource::Provider);


sub _download {
    my ($self, $resource, %options) = @_;
    return $self->{maven_agent}->download($resource->get_artifact(), %options);
}

sub _init {
    my ($self, $maven_agent) = @_;

    $self->Footprintless::Resource::Provider::_init();

    $self->{maven_agent} = $maven_agent;

    return $self;
}

sub resource {
    my ($self, $spec) = @_;

    return $spec if ($spec->isa('Footprintless::Resource::Maven'));

    return Footprintless::Resource::Maven->new(
        $self->{maven_agent}->resolve_or_die(
            ref($spec) ? $spec->{coordinate} : $spec));
}

sub supports {
    my ($self, $resource) = @_;

    return 1 if ($resource->isa('Footprintless::Resource::Maven'));

    my $ref = ref($resource);
    return 1 if (!$ref && $resource =~ /^(?:[^:]+:){2,4}[^:]+$/);
    return 1 if ($ref eq 'HASH' && $resource->{type} eq 'maven');

    return 0; 
}

1;
