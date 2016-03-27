use strict;
use warnings;

package Footprintless::App::Command::overlay;

# ABSTRACT: Performs an action on an overlay.
# PODNAME: Footprintless::App::Command::overlay

use Carp;
use Footprintless::App -command;
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

    if ($self->{action} eq 'clean') {
        $logger->info('Performing clean...');
        $self->{overlay}->clean();
    }
    elsif ($self->{action} eq 'initialize') {
        $logger->info('Performing initialize...');
        $self->{overlay}->initialize();
    }
    elsif ($self->{action} eq 'update') {
        $logger->info('Performing update...');
        $self->{overlay}->update();
    }
    else {
        croak("whoops, validation is broken, fix it");
    }

    $logger->info('Done...');
}

sub opt_spec {
    return (
        ["log=s", "will set the log level",],
    );
}

sub usage_desc { 
    return "fpl overlay [COORDINATE] [ACTION] %o";
}

sub validate_args {
    my ($self, $opts, $args) = @_;
    my ($coordinate, $action) = @$args;

    $self->usage_error("coordinate is required") unless @$args;

    my $footprintless = $self->app()->footprintless();
    eval {
        $self->{overlay} = $self->app()->footprintless()->overlay($coordinate);
    };
    $self->usage_error("invalid coordinate [$coordinate]: $@") if ($@);

    $self->{action} = $action || 'update';
    $self->usage_error("invalid action [$action], must be one of clean, initialize, update")
        unless ($self->{action} =~ /^clean|initialize|update$/);
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
