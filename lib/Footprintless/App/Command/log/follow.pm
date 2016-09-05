use strict;
use warnings;

package Footprintless::App::Command::log::follow;

use parent qw(Footprintless::App::Action);

use Footprintless::App -ignore;
use Log::Any;

my $logger = Log::Any->get_logger();

sub execute {
    my ($self, $footprintless, $coordinate, $opts, $args) = @_;

    $self->{log}->follow(
        runner_options => {out_handle => \*STDOUT},
        ($opts->{until} ? (until => $opts->{until}) : ()));

    $logger->info('Done...');
}

sub opt_spec {
    return (
        ['until=s', 'a regex used to determine when to stop following the log']
    );
}

sub validate_args {
    my ($self, $footprintless, $coordinate, $opts, $args) = @_;

    eval {
        $self->{log} = $footprintless->log($coordinate);
    };
    $self->usage_error("invalid coordinate [$coordinate]: $@") if ($@);
}

1;

__END__

=for Pod::Coverage execute opt_spec usage_desc validate_args
