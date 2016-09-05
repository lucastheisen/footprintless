use strict;
use warnings;

package Footprintless::App::Command::service;

use Footprintless::App -command;
use Footprintless::Util qw(exit_due_to);
use Log::Any;

my $logger = Log::Any->get_logger();

# ABSTRACT: Performs an action on a service.
# PODNAME: Footprintless::App::Command::service

sub execute {
    my ($self, $opts, $args) = @_;
    my ($coordinate, $action) = @$args;

    if ($opts->{log}) {
        $self->_configure_logging($opts->{log});
    }

    $logger->debugf('executing %s for %s', $action, $coordinate);
    eval {
        $self->{service}->execute($action);
    };
    if ($@) {
        if (ref($@) && $@->isa('Footprintless::InvalidEntityException')) {
            $self->usage_error($@);
        }
        exit_due_to($@, 1);
    }
}

sub usage_desc { 
    return "fpl service [COORDINATE] [ACTION] %o" 
}

sub validate_args {
    my ($self, $opt, $args) = @_;
    my ($coordinate, $action) = @$args;

    $self->usage_error("coordinate is required") unless ($coordinate);
    $self->usage_error("action is required") unless ($action);

    my $footprintless = $self->app()->footprintless();
    eval {
        $self->{service} = $self->app()->footprintless()->service($coordinate);
    };
    if ($@) {
        if (ref($@) && $@->isa('Footprintless::InvalidEntityException')) {
            $self->usage_error($@);
        }
        else {
            $self->usage_error("invalid coordinate [$coordinate]: $@");
        }
    }
}

1;

__END__

=head1 SYNOPSIS

    fpl service foo.prod.web.service kill
    fpl service foo.dev.app.service start
    fpl service bar.qa.db.service status
    fpl service baz.beta.support.service stop

=head1 DESCRIPTION

Performs actions on a service.  The default actions are:

    kill - kills the service abruptly
    start - starts the service
    status - checks the status of the service (running/stopped)
    stop - stops the service

For detail action configuration see L<Footprintless::Service>. 
