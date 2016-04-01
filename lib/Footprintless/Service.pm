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
use Footprintless::InvalidEntityException;
use Footprintless::Localhost;
use Footprintless::Util qw(
    invalid_entity
);
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
            $action = $actions_spec->{command_args};
        }
        elsif ($actions_spec->{use_pid}) {
            invalid_entity("pid_file or pid_command required for [$action]",
                $self->{coordinate})
                unless ($self->{spec}{pid_file} || $self->{spec}{pid_command});

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
                    "if [[ -n \$pid ]] && \$(kill -0 \$pid 2> /dev/null)",
                    "then printf '$command_name (pid \%s) is running...' \"\$pid\"",
                    "else printf '$command_name is stopped...'",
                    "fi",
                    {subshell => 'bash -c '}
                )
            }
            else {
                invalid_entity("use_pid not supported for [$action]",
                    $self->{coordinate});
            }
        }
    }

    invalid_entity("no command specified for [$action]", $self->{coordinate}) 
        unless ($command);
    return "$command $action";
}

sub execute {
    my ($self, $action) = @_;
    $self->{command_runner}->run_or_die(
        command(
            $self->_command($action),
            $self->{command_options}),
        {out_handle => \*STDOUT});
}

sub _init {
    my ($self, $factory, $coordinate, %options) = @_;
    $logger->tracef("coordinate=[%s]\noptions=[%s]", $coordinate, \%options);

    $self->{entity} = $factory->entities();
    $self->{coordinate} = $coordinate;
    $self->{spec} = $self->{entity}->get_entity($coordinate);

    $self->{factory} = $factory;
    $self->{command_runner} = $factory->command_runner();
    $self->{command_options} = $factory->command_options(%{$self->{spec}});

    return $self;
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

    # Standard way of getting a service
    use Footprintless;
    my $service = Footprintless->new()->service();

    $service->stop();

    $service->start();

    $service->status();

    $service->kill();

=head1 DESCRIPTION

Manages services.  Allows you to start, stop, check the status of, and
kill services.  Additional actions can be configured as well.

=head1 ENTITIES

A simple service (the most common case) can be defined:

    service => {
        command => '/opt/foo/bar.sh',
        pid_file => '/var/run/bar/bar.pid'
    }

A more complex service might be defined:

    service => {
        actions => {
            debug => {command_args => "jpda start"},
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

=constructor new($entity, $coordinate, %options)

Constructs a new service configured by C<$entities> at C<$coordinate>.  
The supported options are:

=over 4

=item command_options_factory

The command options factory to use.  Defaults to an instance of
L<Footprintless::CommandOptionsFactory> using the C<localhost> instance
of this object.

=item command_runner

The command runner to use.  Defaults to an instance of 
L<Footprintless::CommandRunner::IPCRun>.

=item localhost

The localhost alias resolver to use.  Defaults to an instance of
L<Footprintless::Localhost> configured with C<load_all()>.

=back

=method execute($action)

Executes C<$action> on the service.

=method kill()

Kills the service.

=method start()

Starts the service.

=method status()

Prints out the status of the service.

=method stop()

Stops the service.

=head1 SEE ALSO

Config::Entities
Footprintless
Footprintless::CommandOptionsFactory
Footprintless::CommandRunner
Footprintless::Localhost

