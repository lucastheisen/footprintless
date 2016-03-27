use strict;
use warnings;

package Footprintless::App::Command::log;

# ABSTRACT: Provides access to log files.
# PODNAME: Footprintless::App::Command::log

use Footprintless::App -command;
use Footprintless::App::UsageException;
use Footprintless::Util qw(exit_due_to);

my $logger = Log::Any->get_logger();

sub _configure_logging {
    my ($self, $level) = @_;
    require Log::Any::Adapter;
    Log::Any::Adapter->set('Stderr', 
        log_level => Log::Any::Adapter::Util::numeric_level($level));
}

sub execute {
    my ($self, $opts, $args) = @_;
    my ($coordinate, $action) = @$args;

    if ($opts->{log}) {
        $self->_configure_logging($opts->{log});
    }

    $action ||= 'follow';

    eval {
        if (!$action || $action eq 'follow') {
            $self->{log}->follow(
                runner_options => {out_handle => \*STDOUT},
                ($opts->{until} ? (until => $opts->{until}) : ()));
        }
        elsif ($action eq 'tail') {
            $self->{log}->tail(
                runner_options => {out_handle => \*STDOUT},
                ($opts->{arg} ? (args => $opts->{arg}) : ()));
        }
        elsif ($action eq 'head') {
            $self->{log}->head(
                runner_options => {out_handle => \*STDOUT},
                ($opts->{arg} ? (args => $opts->{arg}) : ()));
        }
        elsif ($action eq 'cat') {
            $self->{log}->cat(
                runner_options => {out_handle => \*STDOUT},
                ($opts->{arg} ? (args => $opts->{arg}) : ()));
        }
        elsif ($action eq 'grep') {
            $self->{log}->grep(
                runner_options => {out_handle => \*STDOUT},
                ($opts->{arg} ? (args => $opts->{arg}) : ()));
        }
        else {
            die(Footprintless::App::UsageException->new(
                "invalid action [$action]"));
        }
    };
    if ($@) {
        if (ref($@) && ($@->isa('Footprintless::InvalidEntityException'))
            || $@->isa('Footprintless::App::UsageException')) {
            $self->usage_error($@);
        }
        exit_due_to($@, 1);
    }
}

sub opt_spec {
    return (
        ["log=s", "will set the log level",],
        ["arg=s@", "arguments to the action, multiple allowed",],
        ["until=s", "a perl regex pattern indicating the follow should stop",],
    );
}

sub usage_desc { 
    return "fpl log [COORDINATE] <ACTION> %o" 
}

sub validate_args {
    my ($self, $opts, $args) = @_;
    my ($coordinate, $action) = @$args;

    $self->usage_error("coordinate is required") unless @$args;

    my $footprintless = $self->app()->footprintless();
    eval {
        $self->{log} = $footprintless->log($args->[0]);
    };
    if ($@) {
        if (ref($@) && $@->isa('Footprintless::InvalidEntityException')) {
            $self->usage_error($@);
        }
        $self->usage_error("invalid coordinate [$coordinate]: $@");
    }
}

1;

__END__

=head1 SYNOPSIS

  fpl log foo.dev.tomcat.logs.catalina follow
  fpl log foo.prod.web.logs.access grep --arg "--color" --arg "'GET /foo/bar'"

=head1 DESCRIPTION

Provides various forms of read access to log files.  The available actions 
are:

    cat      read the entire file
    follow   essentially tail -f
    grep     search for specific content in the file
    head     read from the beginning of the file
    tail     read from the end of the file

If no action is specified, C<follow> is implied.  For detailed configuration 
see L<Footprintless::Log>. 
