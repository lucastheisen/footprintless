use strict;
use warnings;

package Footprintless::App::Command::deployment::deploy;

# ABSTRACT: deploys all files managed by the deployment
# PODNAME: Footprintless::App::Command::deployment::deploy

use parent qw(Footprintless::App::Action);

use Footprintless::App -ignore;
use Log::Any;

my $logger = Log::Any->get_logger();

sub execute {
    my ($self, $opts, $args) = @_;

    if ($opts->{clean}) {
        $logger->info('Performing clean...');
        $self->{deployment}->clean();
    }
    $logger->info('Performing deploy...');
    $self->{deployment}->deploy();

    $logger->info('Done...');
}

sub opt_spec {
    return (
        ["clean", "will cause clean to be run before deploy"]
    );
}

sub usage_desc { 
    return "fpl deployment DEPLOYMENT_COORD deploy %o";
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

=for Pod::Coverage execute opt_spec usage_desc validate_args
