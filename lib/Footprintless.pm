use strict;
use warnings;

package Footprintless;

# ABSTRACT: A utility for managing systems with minimal installs
# PODNAME: Footprintless

use Carp;
use Config::Entities;
use Footprintless::CommandFactory;
use Footprintless::CommandRunner;
use Footprintless::Localhost;
use Footprintless::Util qw(default_command_runner);
use Log::Any;

my $logger = Log::Any->get_logger();

sub new {
    return bless({}, shift)->_init(@_);
}

sub copy {
    my ($self, $source, $destination) = @_;

    #$destination = $self->fill_config(
    #$coordinate,
    #{
    #'path' => 'Config::Entities::entity', 
    #hostname => undef,
    #ssh => undef,
    #ssh_username => undef,
    #sudo_username => undef
    #}, 
    #ancestry => 1);
}

sub fill_config {
    my ($self, $coordinate, $spec, @options) = @_;
    return $self->{config}->fill($coordinate, $spec, @options);
}

sub get_config {
    my ($self, $coordinate) = @_;
    return $self->{config}->get_entity($coordinate);
}

sub _init {
    my ($self, %options) = @_;
    
    $logger->debug( 'creating new Footprintless' );

    if ($options{config}) {
        $self->{config} = Config::Entities->new({entity => $options{config}});
    }
    else {
        if ($options{config_dirs}) {
            my @config_dirs = ref($options{config_dirs}) eq 'ARRAY' 
                ? @{$options{config_dirs}} 
                : $options{config_dirs};
            my %config_options = (
                $options{config_properties} 
                    ? ('properties' => $options{config_properties}) 
                    : (),
                $options{config_properties_file} 
                    ? ('properties_file' => $options{config_properties_file}) 
                    : (),
            );
            
            $self->{config} = Config::Entities->new(@config_dirs, 
                (keys(%config_options) ? \%config_options : ()));
        }
        else {
            croak('config or config_dirs is required');
        }
    }
    $self->{command_factory} = 
        Footprintless::CommandFactory->new($self->{config});
    $self->{command_runner} = $options{command_runner} 
        || default_command_runner();
    $self->{localhost} = Footprintless::Localhost->new(
        $options{localhost_aliases} 
            ? (aliases => $options{localhost_aliases}) 
            : ())->load_all();

    return $self;
}

sub _location {
    my ($self, $location) = @_;

    my ($location_path, $location_options);
    my $ref = ref($location);
    if ($ref eq 'ARRAY') {
        $location_path = $location->[0];
        $location_options = $self->_location_options($location->[1]);
    }

    return wantarray 
        ? ($location_path, $location_options)
        : {
            'path' => $location_path, 
            'options' => $location_options
        };
}

sub tail {
    my ($self, $coordinate) = @_;

    $self->{command_runner}->run_or_die(
        $self->{command_factory}->tail_command($coordinate));
}

1;

__END__
=head1 SYNOPSIS

  use Footprintless;

=head1 DESCRIPTION

This module ...

=constructor new(\%entity, %options)

Creates a new Footprintless agent.  Available options are:

=over 4

=item resolver

A preconfigured instance of Template::Resolver.  If not supplied, one
will be created with default configuration. 

=back

=method update($entity)

Will read from C<$file_handle_or_name> replacing all placeholders prefixed by 
C<$placeholder_prefix>.

=head1 SEE ALSO
Config::Entities
Template::Resolver
https://github.com/lucastheisen/footprintless

