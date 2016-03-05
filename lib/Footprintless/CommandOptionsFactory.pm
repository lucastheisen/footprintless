use strict;
use warnings;

package Footprintless::CommandOptionsFactory;

use Carp;
use Footprintless::Localhost;
use Footprintless::Command;

sub new {
    return bless({}, shift)->_init(@_);
}

sub command_options {
    my ($self, %options) = @_;

    $options{ssh} = $self->{default_ssh} unless ($options{ssh});
    delete($options{sudo_username}) unless ($options{sudo_username});
    delete($options{username}) unless ($options{username});
    if ($self->{localhost} && $options{hostname} &&
        $self->{localhost}->is_alias($options{hostname})) {
        delete($options{hostname});
    }

    return Footprintless::Command::command_options(%options);
}

sub _init {
    my ($self, %options) = @_;

    $self->{localhost} = $options{localhost}
        || Footprintless::Localhost->new()->load_all();
    $self->{default_ssh} = $options{default_ssh} || 'ssh -q';

    return $self;
}

1;
