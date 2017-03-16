use strict;
use warnings;

package Footprintless::App::Command::service;

use Footprintless::App -command;
use Footprintless::Util qw(exit_due_to);
use Log::Any;

my $logger = Log::Any->get_logger();

# ABSTRACT: Performs an action on one or more services.
# PODNAME: Footprintless::App::Command::service

sub execute {
    my ($self, $opts, $args) = @_;
    my ($coordinate, $action) = @$args;

    foreach my $target (@{$self->{targets}}) {
        $logger->debugf('executing %s for %s', $action, 
            $target->{coordinate});
        eval {
            $target->execute($action);
        };
        if ($@) {
            if (ref($@) && $@->isa('Footprintless::InvalidEntityException')) {
                $self->usage_error($@);
            }
            exit_due_to($@, 1);
        }
    }
}

sub usage_desc { 
    return "fpl service SERVICE_COORD ACTION" 
}

sub validate_args {
    my ($self, $opt, $args) = @_;
    my ($coordinate, $action, @sub_coordinates) = @$args;

    $self->usage_error("coordinate is required") unless ($coordinate);
    $self->usage_error("action is required") unless ($action);

    my $footprintless = $self->app()->footprintless();

    my @target_coordinates = @sub_coordinates
        ? map {"$coordinate.$_"} @sub_coordinates
        : ($coordinate);

    my @targets = ();
    foreach my $target_coordinate (@target_coordinates) {
        eval {
            push(@targets, $footprintless->service($target_coordinate));
        };
        if ($@) {
            if (ref($@) && $@->isa('Footprintless::InvalidEntityException')) {
                $self->usage_error($@);
            }
            else {
                $self->usage_error("invalid coordinate [$target_coordinate]: $@");
            }
        }
    }
    $self->{targets} = \@targets;
}

1;

__END__

=head1 SYNOPSIS

    # one service at a time:
    
    fpl service foo.prod.web.service kill
    fpl service foo.dev.app.service start
    fpl service bar.qa.db.service status
    fpl service baz.beta.support.service stop

    # or multiple services:
    
    # starts:
    #   - baz.beta.support.service
    #   - baz.beta.web.service
    #   - baz.beta.app.service
    fpl service baz.beta start support.service web.service app.service

=head1 DESCRIPTION

Performs actions on a service.  

Base actions:

    kill: kills the service abruptly
   start: starts the service
  status: checks the status of the service (running/stopped)
    stop: stops the service

Additional actions can be defined by your entity based on the service 
commands actual capabilities.
