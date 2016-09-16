use strict;
use warnings;

package Footprintless::App::Command::overlay;

# ABSTRACT: Performs an action on an overlay.
# PODNAME: Footprintless::App::Command::overlay

use parent qw(Footprintless::App::ActionCommand);

sub _actions {
    return (
        'clean' => 'Footprintless::App::Command::overlay::clean',
        'initialize' => 'Footprintless::App::Command::overlay::initialize',
        'update' => 'Footprintless::App::Command::overlay::update'
    );
}

sub _default_action {
    return 'update'
}

sub usage_desc { 
    return "fpl overlay OVERLAY_COORD ACTION %o" 
}

1;

__END__

=head1 SYNOPSIS

  fpl overlay OVERLAY_COORD clean
  fpl overlay OVERLAY_COORD initialize
  fpl overlay OVERLAY_COORD update
  fpl overlay OVERLAY_COORD # same as update

=head1 DESCRIPTION

Performs actions on an overlay. 

=head1 SEE ALSO

Footprintless::Overlay
Footprintless::App::Command::overlay::clean
Footprintless::App::Command::overlay::initialize
Footprintless::App::Command::overlay::update
