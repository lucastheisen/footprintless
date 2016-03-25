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
        if (ref($options{entities}) eq 'HASH') {
            $self->{entities} = Config::Entities->new(
                {entity => $options{entities}});
        }
        elsif ($options{entities}->isa('Config::Entities')) {
            $self->{entities} = $options{entities};
        }
        else {
            croak('illegal entities, must be hashref, or Config::Entities');
        }
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

    # Deploy initialize, start, and follow the log of the foo
    $footprintless->overlay('dev.foo.overlay')->initialize();
    $footprintless->service('dev.foo.service')->start();
    $footprintless->log('dev.foo.logs.app')->follow();

=head1 DESCRIPTION

Footprintless is an automation framework with an application frontend for
managing diverse software stacks in a consistent fashion.  It provides a
minimally invasive approach to configuration management.  At its core, 
L<Config::Entities> are used to define the whole
L<system|https://en.wikipedia.org/wiki/System>.  Once defined, the
entities are used by all of the Footprintless modules to decouple the 
environment from the action.  The environment is defined by the 
entities used to create 
L<command options|Footprintless::CommandOptionsFactory>.  Specifically:

    hostname
    ssh
    sudo_username
    username

Each module will have its own entities structure, see them for more 
details.

=head1 ENTITIES

An example system my consist of multiple environments, each defined
in their own file:

    ./fooptintless
                  /entities
                           /foo
                               /dev.pm
                               /qa.pm
                               /prod.pm

Each one of them would likely be rather similar, perhaps a variation of:

    return {
        app => {
            deployment => {
                'Config::Entities::inherit' => ['hostname', 'sudo_username'],
                clean => [
                    '/opt/foo/tomcat/conf/Catalina/localhost/',
                    '/opt/foo/tomcat/temp/',
                    '/opt/foo/tomcat/webapps/',
                    '/opt/foo/tomcat/work/'
                ],
                resources => {
                    bar => 'com.pastdev:bar:war:1.0',
                    baz => 'com.pastdev:baz:war:1.0'
                },
                to_dir => '/opt/foo/tomcat/webapps'
            },
            hostname => 'app.pastdev.com',
            logs => {
                catalina => '/opt/foo/tomcat/logs/catalina.out'
            },
            overlay => {
                'Config::Entities::inherit' => ['hostname', 'sudo_username'],
                base_dir => '/home/me/git/foo/base',
                clean => [
                    '/opt/foo/tomcat/'
                ],
                deployment_coordinate => 'foo.dev.app.deployment',
                key => 'T',
                os => 'linux',
                resolver_coordinate => 'foo.dev',
                template_dir => '/home/me/git/foo/template',
                to_dir => '/opt/foo/tomcat'
            },
            sudo_username => 'tomcat',
            tomcat => {
                'Config::Entities::inherit' => ['hostname', 'sudo_username'],
                catalina_base => '/opt/foo/tomcat',
                http => {
                    port => 20080
                },
                service => {
                    'Config::Entities::inherit' => ['hostname', 'sudo_username'],
                    action => {
                        'kill' => { command_args => 'stop -force' },
                        'status' => { use_pid => 1 }
                    },
                    command => '/opt/foo/tomcat/bin/catalina.sh',
                    pid_file => '/opt/foo/tomcat/bin/.catalina.pid',
                },
                shutdown => {
                    port => 20005,
                    password => $properties->{'foo.dev.app.tomcat.shutdown.password'},
                },
                trust_store => {
                    'Config::Entities::inherit' => ['hostname', 'sudo_username'],
                    file => '/opt/foo/tomcat/certs/truststore.jks',
                    include_java_home_cacerts => 1,
                    password => $properties->{'foo.dev.app.tomcat.trust_store.password'},
                }
            }
        }
        web => {
            hostname => 'web.pastdev.com',
            logs => {
                error => '/var/log/httpd/error_log',
                access => '/var/log/httpd/access_log'
            }
            sudo_username => 'apache'
        }
    }

Then when you decide to perform an action, the environment is just part
of the coordinate:

    fpl log foo.dev.app.tomcat.logs.catalina follow

    fpl service foo.qa.app.tomcat.service status

    fpl deployment foo.prod.app.deployment deploy --clean

If using the framework instead, the story is the same:

    my $permission_denied = Footprintless->new()
        ->log('foo.prod.web.logs.error')
        ->grep(options => 'Permission denied');

=constructor new(\%entity, %options)

Creates a new Footprintless factory.  Available options are:

=over 4

=item entities

If supplied, C<entities> will serve as the configuration for this instance.
All other configuration sources will be ignored.  Must be either a hashref, 
or an instance of L<Config::Entities>.

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

Returns the L<agent|LWP::UserAgent> used by this instance. 

=method command_options_factory()

Returns the 
L<command_options_factory|Footprintless::CommandOptionsFactory> used by 
this instance.

=method command_runner()

Returns the L<command_runner|Footprintless::CommandRunner> used by 
this instance.

=method deployment($coordinate, %options)

Returns a new instance of L<Footprintless::Deployment> preconfigured to
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

Returns the L<Config::Entities> that were resolved by this footprintless
instance.

=method localhost()

Returns the L<localhost|Footprintless::Localhost> resolver used by 
this instance.

=method log($coordinate, %options)

Returns a new instance of L<Footprintless::Log> preconfigured to
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

Returns a new instance of L<Footprintless::Overlay> preconfigured to
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

Returns the L<resource_manager|Footprintless::ResourcManager> used by 
this instance.

=method service($coordinate, %options)

Returns a new instance of L<Footprintless::Service> preconfigured to
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

