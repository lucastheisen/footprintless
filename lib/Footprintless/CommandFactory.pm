use strict;
use warnings;

package Footprintless::CommandFactory;

use Carp;
use Footprintless::Command;

sub new {
    return bless({}, shift)->_init(@_);
}

sub _init {
    my ($self, $config) = @_;

    $self->{config} = $config;

    return $self;
}

sub _command_options {
    my ($self, $options) = @_;

    foreach my $key (keys(%$options)) {
        delete $options->{$key} unless defined($options->{$key});
    }

    if ($options->{hostname} && $self->_is_localhost($options->{hostname})) {
        delete $options->{hostname}
    }

    return Footprintless::Command::command_options(%$options);
}

sub _is_localhost {
    my ($self, $hostname) = @_;
    return 1 if ($hostname eq 'localhost' || $hostname eq '127.0.0.1');
    return 0;
}

sub tail_command {
    my ($self, $coordinate, $options) = @_;

    my $config = $self->{config}->fill($coordinate,
        {
            'file' => 'Config::Entities::entity', 
            'hostname' => undef,
            'sudo_username' => undef,
            'ssh' => undef,
            'ssh_username' => undef,
        },
        ancestry => 1);

    croak("invalid coordinate $coordinate") unless($config->{file});

    return Footprintless::Command::tail_command(
        delete $config->{file}, 
        $self->_command_options($config));
}

1;
