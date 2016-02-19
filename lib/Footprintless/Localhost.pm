use strict;
use warnings;

package Footprintless::Localhost;

use Log::Any;

my $logger = Log::Any->get_logger();

sub new {
    return bless( {}, shift )->_init( @_ );
}

sub _add_alias {
    my ($self, $alias) = @_;

    if ( $alias ) {
        $logger->debugf('adding alias [%s]', $alias);
        $self->{aliases}{lc($alias)} = 1;
    }

    return $self;
}

sub _init {
    my ($self, %options) = @_;

    # what gets returned if is_alias( <falsey> );
    $self->{empty} = exists( $options{empty} ) ? $options{empty} : 1;

    $self->_add_alias( 'localhost' )
        ->_add_alias( '127.0.0.1' )
        unless ($options{none});
    
    if ( $options{aliases} ) {
        $self->_add_alias( $_ ) foreach @{$options{aliases}};
    }
    
    return $self;
}

sub load_all {
    shift->load_etc_hosts()
        ->load_hostfqdn()
        ->load_hostname();
}

sub load_etc_hosts {
    my ($self) = @_;

    if (!$self->{loaded}{'/etc/hosts'}) {
        # attempt to load aliases from hosts file
        $logger->debug('loading /etc/hosts');
        eval { 
            require Config::Hosts;
            $logger->debug('have Config::Hosts');
            my $hosts = Config::Hosts->new();
            $hosts->read_hosts();
            my $one_two_seven = $hosts->query_host( '127.0.0.1' );
            if ( $one_two_seven ) {
                $self->_add_alias( $_ ) foreach @{$one_two_seven->{hosts}};
            }
        };
        $self->{loaded}{'/etc/hosts'} = 1;
    }

    return $self;
}

sub load_hostfqdn {
    my ($self) = @_;

    if (!$self->{loaded}{hostfqdn}) {
        # if fqdn is present, add it too...
        $logger->debug('loading hostfqdn');
        require Net::Domain;
        $self->_add_alias( Net::Domain::hostfqdn() );
        $self->{loaded}{hostfqdn} = 1;
    }

    return $self;
}

sub load_hostname {
    my ($self) = @_;

    if (!$self->{loaded}{hostname}) {
        # load alias from hostname
        $logger->debug('loading hostname');
        eval {
            # hostname() croaks on fail, so just ignore
            require Sys::Hostname;
            $self->_add_alias( Sys::Hostname::hostname() );
        };
        $self->{loaded}{hostname} = 1;
    }

    return $self;
}    

sub is_alias {
    my ($self, $hostname) = @_;

    if ( $hostname ) {
        return $self->{aliases}{lc($hostname)};
    }
    else {
        return $self->{empty};
    }
}

sub is_loaded {
    my ($self, $extra) = @_;
    return $self->{loaded} && $self->{loaded}{$extra};
}

1;
