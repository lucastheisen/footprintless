use strict;
use warnings;

package Footprintless::App;

use App::Cmd::Setup -app;

sub footprintless {
    my ($self) = @_;

    if (!defined($self->{footprintless})) {
        require Footprintless;
        $self->{footprintless} = Footprintless->new();
    }

    return $self->{footprintless};
}

1;
