use strict;
use warnings;

package Footprintless::App::Command::deployment;

# ABSTRACT: Performs an action on a deployment.
# PODNAME: Footprintless::App::Command::deployment

use parent qw(Footprintless::App::ActionCommand);

my %actions = (
    'clean' => 'Footprintless::App::Command::deployment::clean',
    'deploy' => 'Footprintless::App::Command::deployment::deploy'
);

sub _action_implementation {
    my ($self, $action) = @_;
    return $actions{$action};
}

1;

__END__

=head1 SYNOPSIS

    fpl deployment project.environment.component.deployment clean
    fpl deployment project.environment.component.deployment deploy
    fpl deployment project.environment.component.deployment deploy --clean

=head1 DESCRIPTION

Performs actions on a deployment. The available actions are:

    clean   removes all files/folders handled by this deployment
    deploy  deploys all the resources handled by this deployment

=head1 SEE ALSO

Footprintless::Deployment
Footprintless::App::Command::deployment::clean
Footprintless::App::Command::deployment::deploy
