use strict;
use warnings;

package Footprintless::CommandFactory;

use Carp;
use Footprintless::Command;

our $AUTOLOAD;

sub new {
    return bless({}, shift)->_init(@_);
}

sub batch_command {
    my ($self, @args) = @_;
    return Footprintless::Command::batch_command(@args);
}

sub command {
    my ($self, @args) = @_;
    return Footprintless::Command::command(@args);
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

sub cp_command {
    my ($self, @args) = @_;
    return Footprintless::Command::cp_command(@args);
}

sub mkdir_command {
    my ($self, @args) = @_;
    return Footprintless::Command::mkdir_command(@args);
}

sub pipe_command {
    my ($self, @args) = @_;
    return Footprintless::Command::pipe_command(@args);
}

sub rm_command {
    my ($self, @args) = @_;
    return Footprintless::Command::rm_command(@args);
}

sub sed_command {
    my ($self, @args) = @_;
    return Footprintless::Command::sed_command(@args);
}

sub tail_command {
    my ($self, @args) = @_;
    return Footprintless::Command::tail_command(@args);
}

sub write_command {
    my ($self, @args) = @_;
    return Footprintless::Command::write_command(@args);
}

1;
