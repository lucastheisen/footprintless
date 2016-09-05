use strict;
use warnings;

package Footprintless::App::Command::log::head;

use parent qw(Footprintless::App::Action);

use Footprintless::App -ignore;
use Log::Any;

my $logger = Log::Any->get_logger();

sub execute {
    my ($self, $footprintless, $coordinate, $opts, $args) = @_;

    $self->{log}->head(
        runner_options => {out_handle => \*STDOUT},
        ($opts->{arg} ? (args => $opts->{arg}) : ()));

    $logger->info('Done...');
}

sub opt_spec {
    return (
        ['arg=s@', 'an argument passed to the command']
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
