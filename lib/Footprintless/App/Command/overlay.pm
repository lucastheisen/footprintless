use strict;
use warnings;

package Footprintless::App::Command::overlay;

# ABSTRACT: Performs an action on an overlay.
# PODNAME: Footprintless::App::Command::overlay

use parent qw(Footprintless::App::ActionCommand);

my %actions = (
    'clean' => 'Footprintless::App::Command::overlay::clean',
    'initialize' => 'Footprintless::App::Command::overlay::initialize',
    'update' => 'Footprintless::App::Command::overlay::update'
);

sub _action_implementation {
    my ($self, $action) = @_;
    return $actions{$action};
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
                 files
    update       process the template files

=head1 SEE ALSO

Footprintless::Overlay
Footprintless::App::Command::overlay::clean
Footprintless::App::Command::overlay::initialize
Footprintless::App::Command::overlay::update
