use strict;
use warnings;

package Footprintless::App::Command::log::head;

# ABSTRACT: output the first part of a file
# PODNAME: Footprintless::App::Command::log::head

use parent qw(Footprintless::App::Action);

use Footprintless::App -ignore;
use Log::Any;

my $logger = Log::Any->get_logger();

sub execute {
    my ($self, $opts, $args) = @_;

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

sub usage_desc { 
    return "fpl log LOG_COORD head %o";
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
