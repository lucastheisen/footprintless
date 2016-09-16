use strict;
use warnings;

package Footprintless::App::Command::overlay::update;

# ABSTRACT: processes the overlay template files only
# PODNAME: Footprintless::App::Command::overlay::clean

use parent qw(Footprintless::App::Action);

use Footprintless::App -ignore;
use Log::Any;

my $logger = Log::Any->get_logger();

sub execute {
    my ($self, $opts, $args) = @_;

    $logger->info('Performing update...');
    $self->{overlay}->update();

    $logger->info('Done...');
}

sub usage_desc { 
    return "fpl overlay OVERLAY_COORD update %o";
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
