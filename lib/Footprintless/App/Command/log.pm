use strict;
use warnings;

package Footprintless::App::Command::log;

# ABSTRACT: Provides access to log files.
# PODNAME: Footprintless::App::Command::log

use parent qw(Footprintless::App::ActionCommand);

sub _actions {
    return (
        'cat' => 'Footprintless::App::Command::log::cat',
        'follow' => 'Footprintless::App::Command::log::follow',
        'grep' => 'Footprintless::App::Command::log::grep',
        'head' => 'Footprintless::App::Command::log::head',
        'tail' => 'Footprintless::App::Command::log::tail',
    );
}

sub _default_action() {return 'follow'}

sub usage_desc { 
    return "fpl log LOG_COORD ACTION %o";
}

1;

__END__

=head1 SYNOPSIS

  fpl log foo.dev.tomcat.logs.catalina follow
  fpl log foo.prod.web.logs.access grep --arg "--color" --arg "'GET /foo/bar'"

=head1 DESCRIPTION

Provides various forms of read access to log files.

=head1 SEE ALSO

Footprintless::Log
Footprintless::App::Command::log::cat
Footprintless::App::Command::log::follow
Footprintless::App::Command::log::grep
Footprintless::App::Command::log::head
Footprintless::App::Command::log::tail
