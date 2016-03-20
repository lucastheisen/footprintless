use strict;
use warnings;

package Footprintless::App::Command::log;

# ABSTRACT: Provides access to log files.
# PODNAME: Footprintless::App::Command::log

use Footprintless::App -command;
use Footprintless::Util qw(exit_due_to);

sub execute {
    my ($self, $opts, $args) = @_;
    my ($coordinate, $action, @action_args) = @$args;

    if ($action eq 'follow') {
        eval {
            $self->{log}->follow(
                ($opts->{until} ? (until => $opts->{until}) : ()),
                runner_options => {out_handle => \*STDOUT});
        };
        exit_due_to($@) if ($@);
    }
    elsif ($action eq 'tail') {
        eval {
            $self->{log}->tail(@action_args);
        };
        exit_due_to($@) if ($@);
    }
    elsif ($action eq 'head') {
        eval {
            $self->{log}->head(@action_args);
        };
        exit_due_to($@) if ($@);
    }
    elsif ($action eq 'cat') {
        eval {
            $self->{log}->cat(@action_args);
        };
        exit_due_to($@) if ($@);
    }
    elsif ($action eq 'grep') {
        eval {
            $self->{log}->grep(@action_args);
        };
        exit_due_to($@) if ($@);
    }
}

sub opt_spec {
    return (
        ["until=s", "a perl regex pattern indicating the follow should stop",],
    );
}

sub usage_desc { 
    return "fpl %o [COORDINATE]" 
}

sub validate_args {
    my ($self, $opts, $args) = @_;
    my ($coordinate, $action) = @$args;

    $self->usage_error("coordinate is required") unless @$args;

    my $footprintless = $self->app()->footprintless();
    eval {
        $self->{log} = $footprintless->log($args->[0]);
    };
    $self->usage_error("invalid coordinate [$coordinate]: $@") if ($@);

    $self->usage_error("invalid action [$action]") 
        unless ($action =~ /^cat|follow|grep|head|tail$/);
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
see L<Footprintless::Log>. 
