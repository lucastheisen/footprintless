use strict;
use warnings;

package Footprintless;

# ABSTRACT: A utility for managing systems with minimal installs
# PODNAME: Footprintless

use Carp;
use Config::Entities;
use Log::Any;

my $logger = Log::Any->get_logger();

sub new {
    return bless({}, shift)->_init(@_);
}

sub agent {
    my ($self) = @_;
    unless ($self->{agent}) {
        require LWP::UserAgent;
        $self->{agent} = LWP::UserAgent->new();
        $self->{agent}->env_proxy();
    }
    return $self->{agent};
}

sub command_factory {
    my ($self) = @_;
    unless ($self->{command_factory}) {
        require Footprintless::CommandFactory;
        $self->{command_factory} = 
            Footprintless::CommandFactory->new(localhost => $self->localhost());
    }
    return $self->{command_factory};
}

sub command_runner {
    my ($self) = @_;
    unless ($self->{command_runner}) {
        require Footprintless::Util;
        $self->{command_runner} = Footprintless::Util::default_command_runner();
    }
    return $self->{command_runner};
}

sub deployment {
    my ($self, $coordinate, %options) = @_;

    require Footprintless::Deployment;
    return Footprintless::Deployment->new($self->{entities}, $coordinate,
        command_factory => $options{command_factory} || $self->command_factory(),
        command_runner => $options{command_runner} || $self->command_runner(),
        localhost => $options{localhost} || $self->localhost(),
        resource_manager => $options{resource_manager} || $self->resource_manager());
}

sub entities {
    my ($self) = @_;
    return $self->{entities};
}

sub _init {
    my ($self, %options) = @_;
    
    $logger->debug( 'creating new Footprintless' );

    if ($options{entities}) {
        $self->{entities} = $options{entities};
    }
    else {
        my $fpl_home;
        if ($options{fpl_home}) {
            $fpl_home = $options{fpl_home};
        }
        elsif ($ENV{FPL_HOME}) {
            $fpl_home = $ENV{FPL_HOME}
        }
        else {
            $fpl_home = File::Spec->catdir($ENV{HOME}, '.footprintless');
        }

        my @config_dirs = ();
        if ($options{config_dirs}) {
            @config_dirs = ref($options{config_dirs}) eq 'ARRAY'
                ? @{$options{config_dirs}}
                : ($options{config_dirs});
        }
        elsif ($ENV{FPL_CONFIG_DIRS}) {
            @config_dirs = _split_dirs($ENV{FPL_CONFIG_DIRS});
        }
        else {
            my $default = File::Spec->catdir($fpl_home, 'config');
            if (-d $default) {
                @config_dirs = ($default);
            }
        }

        my @config_options = ();
        if ($options{config_properties}) {
            push(@config_options, properties_file => $options{config_properties});
        }
        elsif ($ENV{FPL_CONFIG_PROPS}) {
            my @properties = _split_dirs($ENV{FPL_CONFIG_PROPS});
            push(@config_options, properties_file => \@properties);
        }
        else {
            my $default = File::Spec->catdir($fpl_home, 'properties.pl');
            if (-f $default) {
                push(@config_options, properties_file => $default);
            }
        }
            
        $logger->tracef("constructing entities with\n\tconfig_dirs: %s\n\tconfig_options: %s)", 
            \@config_dirs, {@config_options});
        $self->{entities} = Config::Entities->new(@config_dirs, {@config_options});
    }

    $self->{command_runner} = $options{command_runner};
    $self->{localhost} = $options{localhost};
    $self->{command_factory} = $options{command_factory};

    return $self;
}

sub localhost {
    my ($self) = @_;
    unless ($self->{localhost}) {
        require Footprintless::Localhost;
        $self->{localhost} = Footprintless::Localhost->new()->load_all();
    }
    return $self->{localhost};
}

sub overlay {
    my ($self, $coordinate, %options) = @_;

    require Footprintless::Overlay;
    return Footprintless::Overlay->new($self->{entities}, $coordinate,
        command_factory => $options{command_factory} || $self->command_factory(),
        command_runner => $options{command_runner} || $self->command_runner(),
        localhost => $options{localhost} || $self->localhost(),
        resource_manager => $options{resource_manager} || $self->resource_manager());
}

sub resource_manager {
    my ($self) = @_;
    unless ($self->{resource_manager}) {
        require Footprintless::ResourceManager;
        my @providers = ();
        my $agent = $self->agent();
        if (require Maven::Agent) {
            require Footprintless::Resource::MavenProvider;
            push(@providers, Footprintless::Resource::MavenProvider->new(
                Maven::Agent->new(agent => $agent)));
        }
        require Footprintless::Resource::UrlProvider;
        $self->{resource_manager} = Footprintless::ResourceManager->new(
            @providers, 
            Footprintless::Resource::UrlProvider->new($agent));
    }
    return $self->{resource_manager};
}

sub _split_dirs {
    my ($dirs_string) = @_;

    my @dirs = ();
    my $separator = ($^O eq 'MSWin32') ? ';' : ':';
    foreach my $dir (split(/$separator/, $dirs_string)) {
        $dir =~ s/^\s+//;
        $dir =~ s/\s+$//;
        push(@dirs, $dir);
    }

    return @dirs;
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

