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
use Footprintless::Util qw(
    extract
    invalid_entity
    temp_dir
);
use Log::Any;
use Template::Resolver;
use Template::Overlay;

my $logger = Log::Any->get_logger();

sub new {
    return bless({}, shift)->_init(@_);
}

sub clean {
    my ($self) = @_;

    Footprintless::Util::clean($self->{spec}{clean},
        command_runner => $self->{command_runner},
        command_options => $self->{command_options});
}

sub _init {
    my ($self, $factory, $coordinate, %options) = @_;
    $logger->tracef("coordinate=[%s],options=[%s]",
        $coordinate, \%options);

    $self->{entity} = $factory->entities();
    $self->{spec} = $self->{entity}->get_entity($coordinate);
    invalid_entity("base_dir, to_dir, template_dir required") 
        unless ($self->{spec}{base_dir}
            && $self->{spec}{to_dir}
            && $self->{spec}{template_dir});

    $self->{factory} = $factory;
    $self->{localhost} = $factory->localhost();
    $self->{command_runner} = $factory->command_runner();
    $self->{command_options} = $factory->command_options(%{$self->{spec}});

    return $self;
}

sub initialize {
    my ($self) = @_;
    my $is_local = $self->{localhost}->is_alias($self->{spec}{hostname});
    my $to_dir = $is_local ? $self->{spec}{to_dir} : temp_dir();

    $self->clean();

    my ($base_dir, $template_dir, $resource_dir);
    if ($self->{spec}{resource}) {
        $resource_dir = temp_dir();

        my $download_dir = File::Spec->catdir($resource_dir, 'download');
        mkdir($download_dir);
        my $archive = $self->{factory}->resource_manager()
            ->download($self->{spec}{resource}, to => $download_dir),

        my $unpack_dir = File::Spec->catdir($resource_dir, 'unpack');
        mkdir($unpack_dir);
        extract($archive, to => $unpack_dir);

        if ($self->{spec}{base_dir}) {
            $base_dir = File::Spec->catdir($unpack_dir, 
                $self->{spec}{base_dir});
        }
        if ($self->{spec}{template_dir}) {
            $template_dir = File::Spec->catdir($unpack_dir, 
                $self->{spec}{template_dir});
        }
    }
    else {
        $base_dir = $self->{spec}{base_dir};
        $template_dir = $self->{spec}{template_dir};
    }

    $self->_overlay($base_dir)->overlay($template_dir, to => $to_dir);

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
    my ($self, $temp_dir, $status) = @_;

    $self->{command_runner}->run_or_die(
        cp_command(
            $temp_dir, 
            $self->{spec}{to_dir},
            $self->{command_options},
            'status' => $status));
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

sub update {
    my ($self) = @_;
    my $is_local = $self->{localhost}->is_alias($self->{spec}{hostname});
    my $to_dir = $is_local ? $self->{spec}{to_dir} : temp_dir();

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
is implemented in L<Template::Overlay>.  

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
        hostname => 'test.pastdev.com',
        overlay => {
            'Config::Entities::inherit' => ['hostname', 'sudo_username'],
            base_dir => '/home/me/foo/base',
            clean => [
                '/opt/foo/tomcat/'
            ],
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

=method clean()

Cleans the overlay.  Each path in the C<clean> entity, will be removed 
from the destination.  If the path ends in a C</>, then after being 
removed, the directory will be recreated.

=method initialize()

Will call C<clean>, then C<overlay> on an instance of L<Template::Overlay>
configured to this entity.  

=method update()

Will overlay I<ONLY> the templated files.  It will not C<clean>, nor copy 
any files from C<base_dir> like C<initialize> does.

=head1 SEE ALSO

Config::Entities
Footprintless
Footprintless::CommandOptionsFactory
Footprintless::CommandRunner
Footprintless::Deployment
Footprintless::Localhost
Footprintless::ResourceManager

