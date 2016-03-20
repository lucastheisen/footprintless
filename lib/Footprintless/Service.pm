use strict;
use warnings;

package Footprintless::Service;

# ABSTRACT: Performs an action on a service.
# PODNAME: Footprintless::Service

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

__END__

=head1 SYNOPSIS

    use Footprintless;

    my $footprintless = Footprintless->new();
    my $service = $footprintless->service();

    $service->stop();

    # Do stuff while service is offline
    
    $service->start();

Or

    use Footprintless::Service;
    my $service = Footprintless::Service->new(
        Config::Entities->new({
            entity => {
                service => {
                    command => '/opt/foo/bar.sh',
                    actions => {
                        kill => {command => '/foo/kill'},
                        start => {command => '/foo/start'},
                        status => {command => '/foo/status'},
                        stop => {command => '/foo/stop'}
                    },
                    pid_file => '/var/run/bar/bar.pid'
                }
            }
        }),
        'service');

    $service->kill();

=head1 DESCRIPTION

Configuration spec:
    <service> : service => <service_spec>

    <service_spec> : {
        <actions>
        <command>
        <hostname>
        <pid_command>
        <pid_file>
        <ssh_username>
        <sudo_username>
    }

    <actions> : actions => <actions_spec>

    <actions_spec> : {
        <action>
    }

    <action> : <action_name> => <action_spec>

    <action_name> : '' 

    <action_spec> : {
        <command>
        <command_args>
        <command_name>
        <use_pid>
    }

    <command> : command => ''

    <command_args> : command_args => ''

    <command_name> : command_name => ''

    <use_pid> : use_id => truthy|falsey

    <hostname> : hostname => ''

    <pid_command> : pid_command => ''

    <pid_file> : pid_file => ''

    <ssh_username> : ssh_username => ''

    <sudo_username> : sudo_username => ''

=head1 EXAMPLES

A simple service (the most common case) can be defined:

    service => {
        command => '/opt/foo/bar.sh',
        pid_file => '/var/run/bar/bar.pid'
    }

A more complex service might be defined:

    service => {
        actions => {
            debug => {command_args => "start -debug"},
            kill => {command_args => "stop -kill"},
            status => {use_pid => 1, command_name => 'tomcat'},
        },
        command => '/opt/tomcat/catalina.sh',
        hostname => 'tomcat.pastdev.com',
        pid_command => 'ps -aef|grep "/opt/tomcat/"|grep -v grep|awk \'{print \$2}\'',
        sudo_username => 'tomcat',
    }

In this case, an additional action, debug, was added, kill was redefined
as a special case of stop, and status was redefined to use the pid 
(ex: kill -0 $pid).  Also, the pid is found via command rather than a file.

