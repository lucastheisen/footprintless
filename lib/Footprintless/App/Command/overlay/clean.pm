use strict;
use warnings;

package Footprintless::App::Command::overlay::clean;

# ABSTRACT: removes all files managed by the overlay
# PODNAME: Footprintless::App::Command::overlay::clean

use parent qw(Footprintless::App::Action);

use Footprintless::App -ignore;
use Log::Any;

my $logger = Log::Any->get_logger();

sub execute {
    my ($self, $opts, $args) = @_;

    $logger->info('Performing clean...');
    $self->{overlay}->clean();

    $logger->info('Done...');
}

sub usage_desc { 
    return "fpl overlay OVERLAY_COORD clean";
}

sub validate_args {
    my ($self, $opts, $args) = @_;

    eval {
        $self->{overlay} = $self->{footprintless}
            ->overlay($self->{coordinate});
    };

    $self->usage_error("invalid coordinate [$self->{coordinate}]: $@") if ($@);
}

1;

__END__

=for Pod::Coverage execute usage_desc validate_args
