use strict;
use warnings;

package Footprintless::App::Command::deployment;

# ABSTRACT: Performs an action on a deployment.
# PODNAME: Footprintless::App::Command::deployment

use Carp;
use Footprintless::App -command;
use Footprintless::Util qw(
    exit_due_to
);
use Log::Any;
use Template::Overlay;
use Template::Resolver;

my $logger = Log::Any->get_logger();

sub _configure_logging {
    my ($self, $level) = @_;
    require Log::Any::Adapter;
    Log::Any::Adapter->set('Stderr', 
        log_level => Log::Any::Adapter::Util::numeric_level($level));
}

sub execute {
    my ($self, $opts, $args) = @_;

    if ($opts->{log}) {
        $self->_configure_logging($opts->{log});
    }

    eval {
        if ($self->{action} eq 'clean') {
            $logger->info('Performing clean...');
            $self->{deployment}->clean();
        }
        elsif ($self->{action} eq 'deploy') {
            if ($opts->{clean}) {
                $logger->info('Performing clean...');
                $self->{deployment}->clean();
            }
            $logger->info('Performing deploy...');
            $self->{deployment}->deploy();
        }
        else {
            $self->usage_error("unsupported action [$self->{action}]");
        }
    };
    if ($@) {
        if (ref($@) && $@->isa('Footprintless::InvalidEntityException')) {
            $self->usage_error($@);
        }
        exit_due_to($@, 1);
    }

    $logger->info('Done...');
}

sub opt_spec {
    return (
        ["clean", "will cause clean to be run before deploy",],
        ["log=s", "will set the log level",],
    );
}

sub usage_desc { 
    return "fpl %o [COORDINATE] [ACTION]";
}

sub validate_args {
    my ($self, $opts, $args) = @_;
    my ($coordinate, $action) = @$args;

    $self->usage_error("coordinate is required") unless @$args;

    my $footprintless = $self->app()->footprintless();
    eval {
        $self->{deployment} = $self->app()->footprintless()->deployment($coordinate);
    };
    $self->usage_error("invalid coordinate [$coordinate]: $@") if ($@);

    $self->{action} = $action || 'deploy';
}

1;

__END__

=head1 SYNOPSIS

  fpl overlay project.environment.component.overlay clean
  fpl overlay project.environment.component.overlay initialize
  fpl overlay project.environment.component.overlay update
  fpl overlay project.environment.component.overlay # same as update

=head1 DESCRIPTION

Performs actions on an overlay.  The available actions are:

    clean        removes all files/folders handled by this overlay
    initialize   clean, then combine the base files and the processed template
                 files, then deploy
    update       process the template files, then deploy

If no action is specified, C<update> is implied.  For detailed configuration 
see L<Footprintless::Overlay>. 
