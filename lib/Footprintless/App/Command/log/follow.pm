use strict;
use warnings;

package Footprintless::App::Command::log::follow;

# ABSTRACT: output the last part of a file and append as the file grows
# PODNAME: Footprintless::App::Command::log::follow

use parent qw(Footprintless::App::Action);

use Footprintless::App -ignore;
use Log::Any;

my $logger = Log::Any->get_logger();

sub execute {
    my ($self, $opts, $args) = @_;

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

sub usage_desc { 
    return "fpl log LOG_COORD follow %o";
}

sub validate_args {
    my ($self, $opts, $args) = @_;

    eval {
        $self->{log} = $self->{footprintless}
            ->log($self->{coordinate});
    };
    $self->usage_error("invalid coordinate [$self->{coordinate}]: $@") if ($@);
}

1;

__END__

=for Pod::Coverage execute opt_spec usage_desc validate_args
