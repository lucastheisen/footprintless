use strict;
use warnings;

package Footprintless::Tunnel;

use Carp;
use File::Path qw(make_path);
use File::Spec;
use File::Temp;
use Footprintless::Mixins qw(
    _entity
);
use IO::Socket::INET;
use Log::Any;
use POSIX ":sys_wait_h";

my $logger = Log::Any->get_logger();

my $number = 0;

sub new {
    return bless( {}, shift)->_init(@_);
}

sub _build_command {
    my ($self, $command) = @_;

    my @command = ($self->{ssh}, ' -S ', $self->{control_socket});

    if ($command eq 'open') {
        push(@command, ' -nfN -oControlMaster=yes -L ');
        if ($self->{local_hostname}) {
            push(@command, $self->{local_hostname}, ':');
        }
        push(@command, $self->{local_port}, ':', 
            $self->{destination_hostname}, ':', 
            $self->{destination_port});
    }
    else { 
        push(@command, ' -O ', $command);
    }
    
    push(@command, ' ');
    if ($self->{tunnel_username}) {
        push(@command, $self->{tunnel_username}, '@');
    }
    push(@command, $self->{tunnel_hostname}, ' 2> /dev/null');
    
    return join('', @command);
}

sub close {
    my ($self) = @_;

    if ( $self->{pid} ) {
        my $command = $self->_build_command('exit');
        $logger->tracef('closing tunnel with: `%s`', $command);
        `$command`;
        my $child = waitpid($self->{pid}, WNOHANG);
        $logger->debugf('forked child closed: %s', $child);
        delete($self->{control_socket});
        delete($self->{pid});
        if ($self->{dynamic_local_port}) {
            delete($self->{local_port});
            delete($self->{dynamic_local_port});
        }
    }
}

sub DESTROY {
    $_[0]->close();
}

sub _find_port {
    # results in slight race condition, but for now, its ok.
    my $sock = IO::Socket::INET->new(
        Proto => 'tcp',
        LocalPort => 0,
        LocalAddr => 'localhost');
    my $port = $sock->sockport();
    $sock->close();
    return $port;
}

sub get_local_hostname {
    return $_[0]->{local_hostname};
}

sub get_local_port {
    return $_[0]->{local_port};
}

sub _init {
    my ($self, $factory, $coordinate, %options) = @_;
    $logger->tracef("coordinate=[%s],options=[%s]",
        $coordinate, \%options);

    $self->{factory} = $factory;
    $self->{coordinate} = $coordinate;

    my $entity = $self->_entity($coordinate);
    $self->{ssh} = $entity->{ssh} || $options{ssh} || 'ssh -q';
    $self->{local_hostname} = $entity->{local_hostname} 
        || $options{local_hostname};
    $self->{local_port} = $entity->{local_port} || $options{local_port};
    $self->{tunnel_hostname} = $entity->{tunnel_hostname} 
        || $options{tunnel_hostname};
    $self->{tunnel_username} = $entity->{tunnel_username} 
        || $options{tunnel_username};
    $self->{destination_hostname} = $entity->{destination_hostname} 
        || $options{destination_hostname};
    $self->{destination_port} = $entity->{destination_port} 
        || $options{destination_port};
    $self->{control_socket_dir} = $entity->{control_socket_dir}
        || $options{control_socket_dir}
        || File::Spec->catdir(
            ($ENV{HOME} ? $ENV{HOME} : $ENV{USERPROFILE}),
            '.ssh', 'control_socket' );

    return $self;
}

sub is_open {
    my ($self) = @_;
    
    if (!$self->{control_socket}) {
        return 0;
    }

    my $command = $self->_build_command('check');
    $logger->tracef('checking tunnel with: `%s`', $command);
    `$command`;
    return (WIFEXITED(${^CHILD_ERROR_NATIVE})
        && WEXITSTATUS(${^CHILD_ERROR_NATIVE}) == 0);
}

sub open {
    my ($self) = @_;

    if (!$self->{local_port}) {
        $self->{local_port} = $self->_find_port();
        $self->{dynamic_local_port} = 1;
    }
    $self->{control_socket} = $self->_temp_control_socket(); 
    $self->{pid} = fork();
    croak("too few resources to open tunnel") if (!defined($self->{pid}));

    if ($self->{pid} == 0) {
        my $command = $self->_build_command('open');
        $logger->debugf('opening tunnel with: `%s`', $command);
        exec($command);
        exit(0);
    }
    
    my $open = 0;
    my $remaining_tries = 10;
    while ($remaining_tries-- > 0) {
        if ($self->is_open()) {
            $open = 1;
            last;
        }
        $logger->tracef('not yet open, %s tries remaining. sleeping...', $remaining_tries);
        sleep(1);
    }
    
    croak('failed to open tunnel') if (!$open);

    $logger->debug('tunnel open');
}

sub _temp_control_socket {
    my ($self) = shift;

    make_path($self->{control_socket_dir});
    return File::Spec->catfile($self->{control_socket_dir}, 
        $$ . '_' . $number++);
}

1;
