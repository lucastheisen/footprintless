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
    my ($coordinate, $action, @rest) = @$args;

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
    return "fpl deployment <COORDINATE> <ACTION> [OPTIONS]";
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

    fpl deployment project.environment.component.deployment clean
    fpl deployment project.environment.component.deployment deploy

=head1 DESCRIPTION

Performs actions on an deployment.  The available actions are:

    clean        removes all files/folders handled by this deployment
    deploy       deploys all resources handled by this deployment

=head1 OPTIONS

=over 4

=item --help

Print help content

=item --log <LEVEL>

Set the level at which log output will be printed to STDERR

=back

=head1 ACTIONS

=head2 clean

Cleans out all the paths from the C<clean> section of the entity.  Be careful
to specify a trailing slash for all directories or it will be treated as
a file and the clean will fail.

=head2 deploy [OPTS]

Deploys all resources from the C<resources> section of the entity to the 
directory specified by the C<to_dir> of the entity.

=over 4

=item --clean

If specified a clean action will be performed before the deploy.

=back

=head1 SEE ALSO

Footprintless::Deployment
