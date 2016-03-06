use strict;
use warnings;

package Footprintless::App::Command::log;

use Footprintless::App -command;
use Footprintless::Util qw(exit_due_to);

sub abstract {
    return 'provides access to log files';
}

sub description {
    return 'provides access to log files';
}

sub execute {
    my ($self, $opts, $args) = @_;
    my $log = $self->app()->footprintless()->log($args->[0]);

    if ($opts->{follow}) {
        eval {
            $log->follow(runner_options => {out_handle => \*STDOUT});
        };
        exit_due_to($@) if ($@);
    }
    elsif ($opts->{tail}) {
        eval {
            $log->tail(lines => $opts->{tail});
        };
        exit_due_to($@) if ($@);
    }
    elsif ($opts->{head}) {
        eval {
            $log->head(lines => $opts->{head});
        };
        exit_due_to($@) if ($@);
    }
    elsif ($opts->{cat}) {
        eval {
            $log->cat();
        };
        exit_due_to($@) if ($@);
    }
    elsif ($opts->{grep}) {
        eval {
            $log->grep(pattern => $opts->{grep});
        };
        exit_due_to($@) if ($@);
    }
}

sub opt_spec {
    return (
        [ "cat",  "prints out the file", ],
        [ "follow",  "follows the log file (tail -f)", ],
        [ "grep=s",  "prints out lines matching the pattern", ],
        [ "head=i",  "prints out n lines from the beginning of the file", ],
        [ "tail=i",  "prints out n lines from the end of the file", ],
    );
}

sub usage_desc { 
    return "fpl %o [COORDINATE]" 
}

sub validate_args {
    my ($self, $opt, $args) = @_;

    $self->usage_error("coordinate is required") unless @$args;
}

1;
