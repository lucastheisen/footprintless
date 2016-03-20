use strict;
use warnings;

package Footprintless::App::Command::service;

use Footprintless::App -command;
use Log::Any;

my $logger = Log::Any->get_logger();

# ABSTRACT: Performs an action on a service.
# PODNAME: Footprintless::App::Command::service

sub _configure_logging {
    my ($self, $level) = @_;
    require Log::Any::Adapter;
    Log::Any::Adapter->set('Stderr', 
        log_level => Log::Any::Adapter::Util::numeric_level($level));
}

sub execute {
    my ($self, $opts, $args) = @_;
    my ($coordinate, $action) = @$args;

    if ($opts->{log}) {
        $self->_configure_logging($opts->{log});
    }

    $logger->debugf('executing %s for %s', $opts->{execute}, $coordinate);
    $self->{service}->execute($action);
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
    my ($coordinate, $action) = @$args;

    $self->usage_error("coordinate is required") unless @$args;

    my $footprintless = $self->app()->footprintless();
    eval {
        $self->{service} = $self->app()->footprintless()->service($coordinate);
    };
    $self->usage_error("invalid coordinate [$coordinate]: $@") if ($@);

    $self->usage_error("invalid action") unless ($action);
}

1;

__END__

=head1 SYNOPSIS

  fpl service project.environment.component.service kill
  fpl service project.environment.component.service start
  fpl service project.environment.component.service status
  fpl service project.environment.component.service stop

=head1 DESCRIPTION

Performs actions on a service.  The default actions are:

    kill - kills the service abruptly
    start - starts the service
    status - checks the status of the service (running/stopped)
    stop - stops the service

For detail action configuration see L<Footprintless::Service>. 
