use strict;
use warnings;

package Footprintless::App::Command::log;

# ABSTRACT: Provides access to log files.
# PODNAME: Footprintless::App::Command::log

use parent qw(Footprintless::App::ActionCommand);

my %actions = (
    'cat' => 'Footprintless::App::Command::log::cat',
    'follow' => 'Footprintless::App::Command::log::follow',
    'grep' => 'Footprintless::App::Command::log::grep',
    'head' => 'Footprintless::App::Command::log::head',
    'tail' => 'Footprintless::App::Command::log::tail',
);

sub _action_implementation {
    my ($self, $action) = @_;
    return $actions{$action};
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

=head1 SEE ALSO

Footprintless::Log
Footprintless::App::Command::log::cat
Footprintless::App::Command::log::follow
Footprintless::App::Command::log::grep
Footprintless::App::Command::log::head
Footprintless::App::Command::log::tail
