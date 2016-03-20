use strict;
use warnings;

package Footprintless::App::Command::service;

use Footprintless::App -command;
use Log::Any;

my $logger = Log::Any->get_logger();

sub abstract {
    return 'performs actions on a service';
}

sub _configure_logging {
    my ($self, $level) = @_;
    require Log::Any::Adapter;
    Log::Any::Adapter->set('Stderr', 
        log_level => Log::Any::Adapter::Util::numeric_level($level));
}

sub description {
    return <<'DESC';
Performs actions on a service.  Unless specified otherwise via
<action_spec>, the [ACTION] argument will be passed through
to the command as is.  There are 4 standard actions:

    kill - kills the service abruptly
    start - starts the service
    status - checks the status of the service (running/stopped)
    stop - stops the service

For example, if command is '/sbin/service foo', and the action
is start, then the effective command would be:

    /sbin/service foo start

If command is overridden via <action_spec> for all supported
actions, then command is not required.

Spec:
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

Examples:
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

DESC
}

sub execute {
    my ($self, $opts, $args) = @_;
    my ($coordinate, $action) = @$args;

    if ($opts->{log}) {
        $self->_configure_logging($opts->{log});
    }

    $logger->debugf('executing %s for %s', $opts->{execute}, $coordinate);
    $self->app()->footprintless()->service($coordinate)
        ->execute($action);
}

sub opt_spec {
    return (
        ["log=s", "will set the log level",],
    );
}

sub usage_desc { 
    return "fpl %o [COORDINATE] [ACTION]" 
}

sub validate_args {
    my ($self, $opt, $args) = @_;
}

1;
