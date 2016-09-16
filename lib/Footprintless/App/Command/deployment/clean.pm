use strict;
use warnings;

package Footprintless::App::Command::deployment::clean;

# ABSTRACT: removes all files managed by the deployment
# PODNAME: Footprintless::App::Command::deployment::clean

use parent qw(Footprintless::App::Action);

use Footprintless::App -ignore;
use Log::Any;

my $logger = Log::Any->get_logger();

sub execute {
    my ($self, $opts, $args) = @_;

    $logger->info('Performing clean...');
    $self->{deployment}->clean();

    $logger->info('Done...');
}

sub usage_desc { 
    return "fpl deployment DEPLOYMENT_COORD clean %o";
}

sub validate_args {
    my ($self, $opts, $args) = @_;

    eval {
        $self->{deployment} = $self->{footprintless}
            ->deployment($self->{coordinate});
    };

    $self->usage_error("invalid coordinate [$self->{coordinate}]: $@") if ($@);
}

1;

__END__

=for Pod::Coverage execute usage_desc validate_args
