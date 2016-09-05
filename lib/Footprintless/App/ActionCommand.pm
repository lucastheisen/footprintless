use strict;
use warnings;

package Footprintless::App::ActionCommand;

use Carp;
use Footprintless::App -command;
use Getopt::Long::Descriptive;

sub _action {
    my ($self, $action_name) = @_;
    my $action = $self->_action_implementation($action_name)
        || croak("invalid action [$action_name]");

    unless (ref($action)) {
        {eval "require $action"}; ## no critic
        $action = $action->new();
    }

    return $action;
}

sub _action_args {
    my ($self, $action, @action_args) = @_;

    local @ARGV = @action_args;
    my ($options, $usage) = describe_options($action->usage_desc(),
        $action->opt_spec());
    return ($usage, $options, \@ARGV);
}

sub _action_implementation {
    croak(ref($_[0]) . ' must implement _action_implementation');
}

sub execute {
    my ($self, $opts, $args) = @_;

    $self->{action}->execute(
        $self->{footprintless},
        $self->{coordinate},
        $self->{action_opts},
        $self->{action_args});
}

sub opt_spec {
    return (
        ["log=s", "will set the log level",],
    );
}

sub validate_args {
    my ($self, $opts, $args) = @_;

    $self->{footprintless} = $self->app()->footprintless();

    my ($coordinate, $action_name, @action_args) = @$args;
    croak("coordinate required") unless ($coordinate);
    croak("action required") unless ($action_name);

    $self->{coordinate} = $coordinate;
    $self->{action} = $self->_action($action_name);
    ($self->{action_usage}, $self->{action_opts}, $self->{action_args}) =
    $self->_action_args($self->{action}, @action_args);

    $self->{action}->validate_args(
        $self->{footprintless},
        $self->{coordinate},
        $self->{action_opts},
        $self->{action_args});
}

1;

__END__
