use strict;
use warnings;

package Footprintless;

# ABSTRACT: A utility for managing systems with minimal installs
# PODNAME: Footprintless

use Carp;
use Config::Entities;
use Footprintless::Util;
use Log::Any;

my $logger = Log::Any->get_logger();

sub new {
    return bless({}, shift)->_init(@_);
}

sub agent {
    my ($self) = @_;
    unless ($self->{agent}) {
        $self->{agent} = Footprintless::Util::agent();
    }
    return $self->{agent};
}

sub command_options_factory {
    my ($self) = @_;
    unless ($self->{command_options_factory}) {
        require Footprintless::CommandOptionsFactory;
        $self->{command_options_factory} = 
            Footprintless::CommandOptionsFactory->new(
                localhost => $self->localhost());
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
        command_options_factory => $options{command_options_factory} 
            || $self->command_options_factory(),
        command_runner => $options{command_runner} 
            || $self->command_runner(),
        localhost => $options{localhost} 
            || $self->localhost(),
        resource_manager => $options{resource_manager} 
            || $self->resource_manager());
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
    $self->{command_options_factory} = $options{command_options_factory};

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

sub log {
    my ($self, $coordinate, %options) = @_;

    require Footprintless::Log;
    return Footprintless::Log->new(
        $self->{entities}, $coordinate,
        command_options_factory => $options{command_options_factory} 
            || $self->command_options_factory(),
        command_runner => $options{command_runner} 
            || $self->command_runner(),
        localhost => $options{localhost} 
            || $self->localhost());
}

sub overlay {
    my ($self, $coordinate, %options) = @_;

    require Footprintless::Overlay;
    return Footprintless::Overlay->new($self->{entities}, $coordinate,
        command_options_factory => $options{command_options_factory} 
            || $self->command_options_factory(),
        command_runner => $options{command_runner} 
            || $self->command_runner(),
        localhost => $options{localhost} 
            || $self->localhost(),
        resource_manager => $options{resource_manager} 
            || $self->resource_manager());
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

sub service {
    my ($self, $coordinate, %options) = @_;

    require Footprintless::Service;
    return Footprintless::Service->new($self->{entities}, $coordinate,
        command_options_factory => $options{command_options_factory} 
            || $self->command_options_factory(),
        command_runner => $options{command_runner} 
            || $self->command_runner(),
        localhost => $options{localhost} 
            || $self->localhost());
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

  my $footprintless = Footprintless->new();

  $footprintless->overlay('dev.foo.overlay')->initialize();
  $footprintless->service('dev.foo.service')->start();

=head1 DESCRIPTION

This module is used to initialize the configuration and provide a factory
for some of the core modules.

=constructor new(\%entity, %options)

Creates a new Footprintless factory.  Available options are:

=over 4

=item entities

If supplied, C<entities> will serve as the configuration for this instance.

=item fpl_home

The root folder for footprintless configuration.  Defaults to the
C<$FPL_HOME> environment variable if set, C<~/.footprintless> if not.

=item config_dirs

The root folder(s) for configuration entities.  Defaults to the 
C<$FPL_CONFIG_DIRS> environment variable if set, C<$FPL_HOME/config> if not.
C<config_dirs> can be a scalar (one directory), or an array ref if there
is more than one directory.  If set via the C<$FPL_CONFIG_DIRS> environment
variable, and you need more than one directory, use a C<;> to delimit on
windows, or a C<:> to delimit on *nix (same as the C<$PATH> variable).

=item config_properties

The properties file(s) used for placeholder replacement for configuration 
entities.  Defaults to the C<$FPL_CONFIG_PROPS> environment variable if set, 
C<$FPL_HOME/properties.pl> if not.  C<config_properties> can be a scalar 
(one file), or an array ref if there is more than one directory.  If set via 
the C<$FPL_CONFIG_PROPS> environment variable, and you need more than one 
directory, use a C<;> to delimit on windows, or a C<:> to delimit on *nix 
(same as the C<$PATH> variable).

=item command_runner

Sets the C<command_runner> for this instance.  Must be an a subclass of
C<Footprintless::CommandRunner>.

=item localhost

Sets the C<localhost> resolver for this instance.  Must be an instance
or subclass of C<Footprintless::Localhost>.

=item command_options_factory

Sets the C<command_options_factory> for this instance.  Must be an instance
or subclass of C<Footprintless::CommandOptionsFactory>.

=back

=method agent()

Returns the C<agent> used by this instance.  Will be an instance of 
C<LWP::UserAgent>.

=method command_options_factory()

Returns the C<command_options_factory> used by this instance.

=method command_runner()

Returns the C<command_runner> used by this instance.

=method deployment($coordinate, %options)

Returns a new instance of C<Footprintless::Deployment> preconfigured to
operate on the deployment at C<$coordinate>.  Supported options are

=over 4

=item command_options_factory

A C<command_options_factory> to use instead of that which is supplied by
this footprintless instance.

=item command_runner

A C<command_runner> to use instead of that which is supplied by
this footprintless instance.

=item localhost

A C<localhost> to use instead of that which is supplied by
this footprintless instance.

=item resource_manager

A C<resource_manager> to use instead of that which is supplied by
this footprintless instance.

=back

=method entities()

Returns the C<Config::Entities> that were resolved by this footprintless
instance.

=method localhost()

Returns the C<localhost> resolver used by this instance.

=method log($coordinate, %options)

Returns a new instance of C<Footprintless::Log> preconfigured to
operate on the log at C<$coordinate>.  Supported options are

=over 4

=item command_options_factory

A C<command_options_factory> to use instead of that which is supplied by
this footprintless instance.

=item command_runner

A C<command_runner> to use instead of that which is supplied by
this footprintless instance.

=item localhost

A C<localhost> to use instead of that which is supplied by
this footprintless instance.

=back

=method overlay($coordinate, %options)

Returns a new instance of C<Footprintless::Overlay> preconfigured to
operate on the overlay at C<$coordinate>.  Supported options are

=over 4

=item command_options_factory

A C<command_options_factory> to use instead of that which is supplied by
this footprintless instance.

=item command_runner

A C<command_runner> to use instead of that which is supplied by
this footprintless instance.

=item localhost

A C<localhost> to use instead of that which is supplied by
this footprintless instance.

=item resource_manager

A C<resource_manager> to use instead of that which is supplied by
this footprintless instance.

=back

=method resource_manager()

Returns the C<resource_manager> used by this instance.

=method service($coordinate, %options)

Returns a new instance of C<Footprintless::Service> preconfigured to
operate on the service at C<$coordinate>.  Supported options are

=over 4

=item command_options_factory

A C<command_options_factory> to use instead of that which is supplied by
this footprintless instance.

=item command_runner

A C<command_runner> to use instead of that which is supplied by
this footprintless instance.

=item localhost

A C<localhost> to use instead of that which is supplied by
this footprintless instance.

=back

=head1 SEE ALSO
Footprintless::Deployment
Footprintless::Log
Footprintless::Overlay
Footprintless::Service
https://github.com/lucastheisen/footprintless

