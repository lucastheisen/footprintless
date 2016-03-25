use strict;
use warnings;

package Footprintless::Overlay;

# ABSTRACT: An overlay manager
# PODNAME: Footprintless::Overlay

use Carp;
use File::Temp;
use Footprintless::Command qw(
    batch_command
    cp_command
    mkdir_command
    rm_command
);
use Footprintless::CommandRunner;
use Footprintless::Localhost;
use Log::Any;
use Template::Resolver;
use Template::Overlay;

my $logger = Log::Any->get_logger();

sub new {
    return bless({}, shift)->_init(@_);
}

sub clean {
    my ($self) = @_;

    my $clean = $self->{spec}{clean};
    if ($clean) {
        $logger->debugf("cleaning overlay %s", $clean);
        eval {
            $self->{command_runner}->run_or_die(
                batch_command(
                    rm_command(@$clean),
                    mkdir_command(@$clean),
                    $self->_command_options()));
        };
        if ($@) {
            $logger->error('clean failed: %s', $@);
            croak($@);
        }
    }
}

sub _command_options {
    my ($self) = @_;
    return $self->{command_options_factory}->command_options(%{$self->{spec}});
}

sub _init {
    my ($self, $entity, $coordinate, %options) = @_;
    $logger->tracef("entity=[%s],coordinate=[%s],options=[%s]",
        $entity, $coordinate, \%options);

    $self->{entity} = $entity;
    $self->{spec} = $entity->get_entity($coordinate);
    croak("base_dir, to_dir, template_dir required") 
        unless ($self->{spec}{base_dir}
            && $self->{spec}{to_dir}
            && $self->{spec}{template_dir});

    $self->{agent} = $options{agent};
    $self->{resource_manager} = $options{resource_manager};
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

    return $self;
}

sub initialize {
    my ($self) = @_;
    my $is_local = $self->{localhost}->is_alias($self->{spec}{hostname});
    my $to_dir = $is_local ? $self->{spec}{to_dir} : $self->_temp_dir();

    $self->clean();

    $self->_overlay($self->{spec}{base_dir})
        ->overlay($self->{spec}{template_dir},
            to => $to_dir);

    if ($self->{spec}{deployment_coordinate}) {
        $logger->debugf('deploying %s', $self->{spec}{deployment_coordinate});
        require Footprintless::Deployment;
        my $deployment = Footprintless::Deployment->new(
            $self->{entity}, $self->{spec}{deployment_coordinate},
            resource_manager => $self->{resource_manager},
            agent => $self->{agent},
            command_runner => $self->{command_runner},
            localhost => $self->{localhost},
            command_options_factory => $self->{command_options_factory});

        # clean will ensure base directory is created if necessary
        my @rebase = $is_local 
            ? () 
            : (rebase => {'from' => "$self->{spec}{to_dir}", to => "$to_dir"});
        $deployment->clean(@rebase);
        $deployment->deploy(@rebase);
    }

    $self->_push_to_destination($to_dir) unless ($is_local);
}

sub _overlay {
    my ($self, $base_dir) = @_;

    my @overlay_opts = ();
    if ($self->{spec}{key}) {
        push(@overlay_opts, key => $self->{spec}{key});
    }

    return Template::Overlay->new($base_dir, 
        $self->_resolver(), @overlay_opts)
}

sub _push_to_destination {
    my ($self, $temp_dir) = @_;

    $self->{command_runner}->run_or_die(
        cp_command(
            $temp_dir, 
            $self->{spec}{to_dir}, $self->_command_options()));
}

sub _resolver {
    my ($self) = @_;

    my @resolver_opts = ();
    if ($self->{spec}{os}) {
        push(@resolver_opts, os => $self->{spec}{os});
    }

    my $resolver_spec = $self->{spec}{resolver_coordinate}
        ? $self->{entity}->get_entity($self->{spec}{resolver_coordinate})
        : $self->{spec};
    return Template::Resolver->new($resolver_spec, @resolver_opts);
}

sub _temp_dir {
    my ($self) = @_;

    File::Temp->safe_level(File::Temp::HIGH);
    return File::Temp->newdir();
}

sub update {
    my ($self) = @_;
    my $is_local = $self->{localhost}->is_alias($self->{spec}{hostname});
    my $to_dir = $is_local ? $self->{spec}{to_dir} : $self->_temp_dir();

    $logger->tracef("update to=[%s], template=[%s]", $to_dir, $self->{spec}{template_dir});
    $self->_overlay($to_dir)
        ->overlay($self->{spec}{template_dir});

    $self->_push_to_destination($to_dir) unless ($is_local);
}

1;

__END__
=head1 SYNOPSIS

    # Standard way of getting an overlay
    use Footprintless;
    my $overlay = Footprintless->new()->overlay('overlay');

    $overlay->clean();

    $overlay->initialize();

    $overlay->update();

=head1 DESCRIPTION

Overlays are a combination of a directory of static files and a directory 
of templated files that will be merged to an output directory.  This
is implemented in L<Template::Overlay>.  If the overlay entity contains a 
C<deployment_coordinate> entity, then any calls to C<initialize> will also 
create a L<Footprintless::Deployment> for the indicated entity and call 
C<deploy> on it.

=head1 ENTITIES

A simple overlay: 

    overlay => {
        base_dir => "/home/me/foo/base",
        clean => [
            "/opt/tomcat/"
        ],
        hostname => 'localhost',
        key => 'T',
        os => 'linux',
        template_dir => "/home/me/foo/template",
        to_dir => '/opt/foo/tomcat'
    }

A more complex example:
    
    foo => {
        deployment => { 
            'Config::Entities::inherit' => ['hostname', 'sudo_username'],
            clean => [
                '/opt/foo/tomcat/conf/Catalina/localhost/',
                '/opt/foo/tomcat/temp/',
                '/opt/foo/tomcat/webapps/',
                '/opt/foo/tomcat/work/'
            ],
            resources => {
                bar => '/home/me/.m2/repository/com/pastdev/bar/1.2/bar-1.2.war',
                baz => {
                    coordinate => 'com.pastdev:baz:war:1.0',
                    'as' => 'foo.war',
                    type => 'maven'
                }
            },
            to_dir => '/opt/foo/tomcat/webapps'
        },
        hostname => 'test.pastdev.com',
        overlay => {
            'Config::Entities::inherit' => ['hostname', 'sudo_username'],
            base_dir => '/home/me/foo/base',
            clean => [
                '/opt/foo/tomcat/'
            ],
            deployment_coordinate => 'foo.deployment',
            key => 'T',
            os => 'linux',
            resolver_coordinate => 'foo',
            template_dir => '/home/me/foo/template',
            to_dir => '/opt/foo/tomcat'
        },
        sudo_username => 'developer',
        tomcat => {
            'Config::Entities::inherit' => ['hostname', 'sudo_username'],
            catalina_base => '/opt/foo/tomcat',
            http => {
                port => 20080
            },
            service => {
                action => {
                    'kill' => { command_args => 'stop -force' },
                    'status' => { use_pid => 1 }
                },
                command => '/opt/foo/tomcat/bin/catalina.sh',
                pid_file => '/opt/foo/tomcat/bin/.catalina.pid',
            },
            shutdown => {
                port => 8505,
                password => $properties->{'foo.tomcat.shutdown.password'},
            },
            trust_store => {
                'Config::Entities::inherit' => ['hostname', 'sudo_username'],
                file => '/opt/foo/tomcat/certs/truststore.jks',
                include_java_home_cacerts => 1,
                password => $properties->{'foo.tomcat.trust_store.password'},
            }
        }
    }

=constructor new($entity, $coordinate, %options)

Constructs a new overlay configured by C<$entities> at C<$coordinate>.  
The supported options are:

=over 4

=item agent

If no C<resource_manager> is provided, then this value is used when 
constructing the default provider(s) for the default resource manager.

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

=item resource_manager

The resource manager to use.  Only used by the deployment if any is
specified.  Defaults to an instance of 
L<Footprintless::ResourceManager> configured to use a 
L<Footprintless::MavenProvider> if L<Maven::Agent> is available, and a
L<Footprintless::UrlProvider> in that order.

=back

=method clean()

Cleans the overlay.  Each path in the C<clean> entity, will be removed 
from the destination.  If the path ends in a C</>, then after being 
removed, the directory will be recreated.

=method initialize()

Will call C<clean>, then C<overlay> on an instance of L<Template::Overlay>
configured to this entity.  Then, if this entity contains a 
C<deployment_coordinate>, an instance of L<Footprintless::Deployment>
will be created for the indicated entity, and its C<deploy> method will be
called.

=method update()

Will overlay I<ONLY> the templated files.  It will not C<clean>, copy any
files from C<base_dir>, or C<deploy> like C<initialize> does.

=head1 SEE ALSO

Config::Entities
Footprintless
Footprintless::CommandOptionsFactory
Footprintless::CommandRunner
Footprintless::Deployment
Footprintless::Localhost
Footprintless::ResourceManager

