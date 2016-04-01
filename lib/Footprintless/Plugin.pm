use strict;
use warnings;

package Footprintless::Plugin;

# ABSTRACT: The base class for footprintless plugins
# PODNAME: Footprintless::Plugin

sub new {
    return bless({}, shift)->_init(@_);
}

sub command_packages {
    my ($self) = @_;
    return (ref($self) . "::Command");
}

sub _init {
    my ($self) = @_;
    return $self;
}

sub factory_methods {
    # return a map of factory methods by name
}

1;
