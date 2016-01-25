use strict;
use warnings;

package Footprintless::App::Command::tail;

use Footprintless::App -command;

sub abstract {
    return 'tail (follow) log files';
}

sub description {
    return 'tail (follow) log files';
}

sub execute {
    my ($self, $opts, $args) = @_;
    $self->app()->footprintless()->tail($args->[0]);
}

sub opt_spec {
    return (
        [ "asdf|R",  "skip reference checks during init", ],
        [ "values|v=s@",  "starting values", { default => [ 0, 1, 3 ] } ],
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
