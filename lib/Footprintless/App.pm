use strict;
use warnings;

package Footprintless::App;

# ABSTRACT: The base application class for fpl
# PODNAME: Footprintless::App

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
__END__
=method footprintless()

Returns the instance of C<Footprintless> for this instance of the app.

=head1 SEE ALSO

App::Cmd
Footprintless
