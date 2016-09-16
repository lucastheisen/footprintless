use strict;
use warnings;

package Footprintless::App::Command::log::cat;

# ABSTRACT: output a file
# PODNAME: Footprintless::App::Command::log::cat

use parent qw(Footprintless::App::Action);

use Footprintless::App -ignore;
use Log::Any;

my $logger = Log::Any->get_logger();

sub execute {
    my ($self, $opts, $args) = @_;

    $self->{log}->cat(
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
    return "fpl log LOG_COORD cat %o";
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
