use strict;
use warnings;

package Footprintless::App::Command::log;

use Footprintless::App -command;

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
        my $err = '';
        eval {
            $log->follow(runner_options => {out_handle => \*STDOUT, err_buffer => \$err});
        };
        if ($@) {
            print(STDERR "$@: $err");
        }
    }
    elsif ($opts->{tail}) {
        croak("tail not yet implemented");
    }
    elsif ($opts->{head}) {
        croak("head not yet implemented");
    }
    elsif ($opts->{cat}) {
        croak("cat not yet implemented");
    }
    elsif ($opts->{grep}) {
        croak("grep not yet implemented");
    }
}

sub opt_spec {
    return (
        [ "cat=i",  "prints out the file", ],
        [ "follow",  "follows the log file (tail -f)", ],
        [ "grep=s",  "searches the file using grep", ],
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
