use strict;
use warnings;

package Footprintless::App::Command::deployment;

# ABSTRACT: Performs an action on a deployment.
# PODNAME: Footprintless::App::Command::deployment

use parent qw(Footprintless::App::ActionCommand);

sub _actions {
    return (
        'clean' => 'Footprintless::App::Command::deployment::clean',
        'deploy' => 'Footprintless::App::Command::deployment::deploy'
    );
}

sub _default_action() {return 'deploy'}

sub usage_desc { 
    return "fpl deployment DEPLOYMENT_COORD ACTION %o";
}

1;

__END__

=head1 SYNOPSIS

    fpl deployment DEPLOYMENT_COORD clean
    fpl deployment DEPLOYMENT_COORD deploy
    fpl deployment DEPLOYMENT_COORD deploy --clean

=head1 DESCRIPTION

Performs actions on a deployment.

=head1 SEE ALSO

Footprintless::Deployment
Footprintless::App::Command::deployment::clean
Footprintless::App::Command::deployment::deploy
