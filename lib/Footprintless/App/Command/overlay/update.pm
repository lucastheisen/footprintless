use strict;
use warnings;

package Footprintless::App::Command::overlay::update;

use parent qw(Footprintless::App::Action);

use Footprintless::App -ignore;
use Log::Any;

my $logger = Log::Any->get_logger();

sub execute {
    my ($self, $footprintless, $coordinate, $opts, $args) = @_;

    $logger->info('Performing update...');
    $self->{overlay}->update();

    $logger->info('Done...');
}

sub usage_desc { 
    return "fpl overlay [COORDINATE] update [OPTIONS]";
}

sub validate_args {
    my ($self, $footprintless, $coordinate, $opts, $args) = @_;

    eval {
        $self->{overlay} = $footprintless->overlay($coordinate);
    };

    $self->usage_error("invalid coordinate [$coordinate]: $@") if ($@);
}

1;

__END__

=for Pod::Coverage execute usage_desc validate_args
