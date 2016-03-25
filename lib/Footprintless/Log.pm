use strict;
use warnings;

package Footprintless::Log;

# ABSTRACT: A log manager
# PODNAME: Footprintless::Log

use Carp;
use Footprintless::Command qw(
    command
    tail_command
);
use Footprintless::CommandOptionsFactory;
use Footprintless::Localhost;
use Log::Any;

my $logger = Log::Any->get_logger();

sub new {
    return bless({}, shift)->_init(@_);
}

sub cat {
    my ($self, %options) = @_;
    my $log_file = $self->{spec};

    my $action_options = scalar($options{options}) 
        ? join(' ', @{$options{options}}, '') 
        : '';

    return $self->{command_runner}->run_or_die(
        command("cat $action_options$log_file", $self->{command_options}));
}

sub follow {
    my ($self, %options) = @_;
    my $log_file = $self->{spec};

    eval {
        $self->{command_runner}->run_or_die(
            tail_command($log_file, follow => 1, $self->{command_options}),
            $self->_runner_options($options{runner_options}, $options{until}));
    };
    if ($@) {
        my $exception = $self->{command_runner}->get_exception();
        croak ($@) unless ($exception && $exception =~ /^until found .*$/) 
    }
}

sub grep {
    my ($self, %options) = @_;
    my $log_file = $self->{spec};

    my $action_options = scalar($options{options}) 
        ? join(' ', @{$options{options}}, '') 
        : '';

    return $self->{command_runner}->run_or_die(
        command("grep $action_options$log_file", $self->{command_options}));
}

sub head {
    my ($self, %options) = @_;
    my $log_file = $self->{spec};

    my $action_options = scalar($options{options}) 
        ? join(' ', @{$options{options}}, '') 
        : '';

    return $self->{command_runner}->run_or_die(
        command("head $action_options$log_file", $self->{command_options}));
}

sub _init {
    my ($self, $entity, $coordinate, %options) = @_;
    $logger->tracef("entity=[%s]\ncoordinate=[%s]\noptions=[%s]",
        $entity, $coordinate, \%options);

    $self->{entity} = $entity;
    $self->{spec} = $entity->get_entity($coordinate);
    if ($options{command_runner}) {
        $self->{command_runner} = $options{command_runner};
    }
    else {
        require Footprintless::CommandRunner::IPCRun;
        $self->{command_runner} = 
            Footprintless::CommandRunner::IPCRun->new();
    }
    $self->{localhost} = $options{localhost}
        || Footprintless::Localhost->new()->load_all();
    $self->{command_options_factory} = $options{command_options_factory}
        || Footprintless::CommandOptionsFactory->new(
            localhost => $self->{localhost});

    $self->{command_options} = $self->{command_options_factory}
        ->command_options(%{
            $entity->fill($coordinate,
                {
                    hostname => undef,
                    ssh => undef,
                    ssh_username => undef,
                    sudo_username => undef
                },
                ancestry => 1)
        });

    return $self;
}

sub _runner_options {
    my ($self, $runner_options, $until) = @_;

    $runner_options = {} unless ($runner_options);

    my $options = {};
    if ($until) {
        if ($runner_options->{out_buffer}) {
            $options->{out_callback} = sub {
                my ($line) = @_;
                ${$runner_options->{out_buffer}} .= "$line\n";
                die ('until found') if ($line =~ $until);
            };
        }
        elsif ($runner_options->{out_callback}) {
            $options->{out_callback} = sub {
                my ($line) = @_;
                &{$runner_options->{out_callback}}($line);
                die ('until found') if ($line =~ $until);
            };
        }
        else {
            my $handle = $runner_options->{out_handle};
            $options->{out_callback} = sub {
                my ($line) = @_;
                print($handle $line) if ($handle);
                die ('until found') if ($line =~ $until);
            };
        }
    }
    else {
        if (exists($runner_options->{out_buffer})) {
            $options->{out_buffer} = $runner_options->{out_buffer};
        }
        elsif (exists($runner_options->{out_callback})) {
            $options->{out_callback} = $runner_options->{out_callback};
        }
        elsif (exists($runner_options->{out_handle})) {
            $options->{out_handle} = $runner_options->{out_handle};
        }
    }

    if (exists($runner_options->{err_buffer})) {
        $options->{err_buffer} = $runner_options->{err_buffer};
    }
    elsif (exists($runner_options->{err_callback})) {
        $options->{err_callback} = $runner_options->{err_callback};
    }
    elsif (exists($runner_options->{err_handle})) {
        $options->{err_handle} = $runner_options->{err_handle};
    }

    return $options;
}

sub tail {
    my ($self, %options) = @_;
    my $log_file = $self->{spec};

    my $action_options = scalar($options{options}) 
        ? join(' ', @{$options{options}}, '') 
        : '';

    return $self->{command_runner}->run_or_die(
        command("tail $action_options$log_file", $self->{command_options}));
}

1;

__END__
=head1 SYNOPSIS

    # Standard way of getting a log
    use Footprintless;
    my $log = Footprintless->new()->log();

    # Wait for a started message before proceeding
    $log->follow(until => qr/Started in \d+/); 

    # Check for errors during startup
    my $error_messages = $log->grep(options => {'ERROR'});

=head1 DESCRIPTION

Provides access to read from log files.

=head1 ENTITIES

A log entity is simply a name/value:

    catalina => '/opt/tomcat/logs/catalina.out'

They will inherit all of their command options (C<hostname>, C<ssh>, 
C<sudo_username>, C<username>)from their ancestry.  Logs are commonly 
grouped together:

    web => {
        hostname => 'web.pastdev.com',
        logs => {
            error => '/var/log/httpd/error_log',
            access => '/var/log/httpd/access_log'
        }
        sudo_username => 'apache'
    }

=constructor new($entity, $coordinate, %options)

Constructs a new log manager configured by the C<$entities> at C<$coordinate>.  
The supported options are:

=over 4

=item command_options_factory

The command options factory to use.  Defaults to an instance of
L<Footprintless::CommandOptionsFactory> using the C<localhost> instance
of this object.

=item command_runner

The command runner to use.  Defaults to an instance of 
L<Footprintless::CommandRunner::IPCRun>.

=item localhost

The localhost alias resolver to use.  Defaults to an instance of
L<Footprintless::Localhost> configured with C<load_all()>.

=back

=method cat(%options)

Executes the C<cat> command on this log.  The available options are:

=over 4

=item options

Command line options passed to the C<cat> command

=back

=method follow(%options)

Executes the C<tail> command with the C<-f> (follow) option and sets
the command runner options to pass the C<STDOUT> from tail to this
C<STDOUT>.

=over 4

=item runner_options

Runner options to be passed on to the command runner.

=item until

The command will stop once the regex supplied is matched to the output.

=back

=method grep(%options)

Executes the C<grep> command on this log.  The available options are:

=over 4

=item options

Command line options passed to the C<grep> command

=back

=method head(%options)

Executes the C<head> command on this log.  The available options are:

=over 4

=item options

Command line options passed to the C<head> command

=back

=method tail(%options)

Executes the C<tail> command on this log.  The available options are:

=over 4

=item options

Command line options passed to the C<tail> command

=back

=head1 SEE ALSO

Config::Entities
Footprintless
Footprintless::CommandOptionsFactory
Footprintless::CommandRunner
Footprintless::Localhost
