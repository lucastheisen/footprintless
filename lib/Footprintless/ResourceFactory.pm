use strict;
use warnings;

package Footprintless::ResourceFactory;

use Carp;
use Config::Entities;

sub new {
    return bless({}, shift)->_init(@_);
}

sub entity_resource {
    my ($self, $coordinate) = @_;
}

sub _init {
    my ($self, $config) = @_;

    if ($config->isa('Config::Entities')) {
        $self->{config} = $config;
    }
    elsif (ref($config) eq 'HASH') {
        $self->{config} = Config::Entities->new(
            entity => $config);
    }
    else {
        croak('invalid config');
    }

    return $self;
}

sub maven_resource {
    my ($self, $coordinate) = @_;
}

sub path_resource {
    my ($self, $path, $coordinate) = @_;

    my $resource{path} = $spec->[0];
    my $resource{path_options} = $self->{config}->fill(
        $spec->[1],
        {
            hostname => undef,
            ssh => undef,
            ssh_username => undef,
            sudo_username => undef
        },
        ancestry => 1);
}

1;
