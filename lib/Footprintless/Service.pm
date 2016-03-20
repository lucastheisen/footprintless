use strict;
use warnings;

package Footprintless::Service;

use Carp;
use Footprintless::Command qw(
    batch_command
    command
);;
use Footprintless::CommandOptionsFactory;
use Footprintless::Localhost;
use Log::Any;

my $logger = Log::Any->get_logger();

sub new {
    return bless({}, shift)->_init(@_);
}

sub kill {
    $_[0]->execute('kill');
}

sub _command {
    my ($self, $action) = @_;
    my $command = $self->{spec}{command};
    my $actions_spec = $self->{spec}{actions}{$action};
    if ($actions_spec) {
        if ($actions_spec->{command}) {
            return $actions_spec->{command};
        }
        elsif ($actions_spec->{command_args}) {
            return "$command $actions_spec->{command_args}";
        }
        elsif ($actions_spec->{use_pid}) {
            my $pid_file = $self->{spec}{pid_file};
            my $pid_command = $pid_file
                ? "cat $pid_file"
                : $self->{spec}{pid_command};
            if ($action eq 'kill') {
                return "kill -KILL \$($pid_command)";
            }
            elsif ($action eq 'status') {
                my $command_name = $actions_spec->{command_name} || $command || 'command';
                return batch_command(
                    "pid=\$($pid_command)",
                    "if \$(kill -0 \$pid 2> /dev/null)",
                    "then printf '$command_name (pid \%s) is running...' \"\$pid\"",
                    "else printf '$command_name is stopped...'",
                    "fi",
                    {subshell => 'bash -c '}
                )
            }
            else {
                croak("use_pid not supported for $action");
            }
        }
    }
    return "$command $action";
}

sub _command_options {
    my ($self) = @_;
    return $self->{command_options_factory}->command_options(%{$self->{spec}});
}

sub _init {
    my ($self, $entity, $coordinate, %options) = @_;
    $logger->tracef("entity=[%s]\ncoordinate=[%s]\noptions=[%s]",
        $entity, $coordinate, \%options);

    $self->{entity} = $entity;
    $self->{spec} = $entity->get_entity($coordinate);
    if ($options{command_runner}) {
        $self->{command_runner} = $options{command_runner};
    }
    else {
        require Footprintless::CommandRunner::IPCRun;
        $self->{command_runner} = 
            Footprintless::CommandRunner::IPCRun->new();
    }
    $self->{localhost} = $options{localhost}
        || Footprintless::Localhost->new()->load_all();
    $self->{command_options_factory} = $options{command_options_factory}
        || Footprintless::CommandOptionsFactory->new(
            localhost => $self->{localhost});

    return $self;
}

sub execute {
    my ($self, $action) = @_;
    $self->{command_runner}->run_or_die(
        command(
            $self->_command($action),
            $self->_command_options()),
        {out_handle => \*STDOUT, err_handle => \*STDERR});
}

sub start {
    $_[0]->execute('start');
}

sub status {
    $_[0]->execute('status');
}

sub stop {
    $_[0]->execute('stop');
}

1;
