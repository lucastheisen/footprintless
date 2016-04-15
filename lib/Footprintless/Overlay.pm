use strict;
use warnings;

package Footprintless::Overlay;

# ABSTRACT: An overlay manager
# PODNAME: Footprintless::Overlay

use Carp;
use Footprintless::Mixins qw (
    _clean
    _entity
    _local_template
    _push_to_destination
    _sub_coordinate
    _sub_entity
);
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
    $self->_clean();
}

sub _init {
    my ($self, $factory, $coordinate, %options) = @_;
    $logger->tracef("coordinate=[%s],options=[%s]",
        $coordinate, \%options);

    $self->{factory} = $factory;
    $self->{coordinate} = $coordinate;

    return $self;
}

sub initialize {
    my ($self) = @_;
    $self->_local_template_with_base_and_template(
        sub {
            my ($base_dir, $template_dir, $to_dir) = @_;
            $self->clean();
            $self->_overlay($base_dir)->overlay($template_dir, to => $to_dir);
        });
}

sub _local_template_with_base_and_template {
    my ($self, $local_work) = @_;
    $self->_local_template(
        sub {
            my ($to_dir) = @_;
            my $base_dir = $self->_sub_entity('base_dir');
            my $template_dir = $self->_sub_entity('template_dir');
            my $resource = $self->_sub_entity('resource');
            if ($resource) {
                my $unpack_dir = temp_dir();
                extract($self->_download($resource), to => $unpack_dir);

                if ($base_dir) {
                    $base_dir = File::Spec->catdir($unpack_dir, $base_dir);
                }
                if ($template_dir) {
                    $template_dir = File::Spec->catdir($unpack_dir, $template_dir);
                }
            }

            &$local_work($base_dir, $template_dir, $to_dir);
        });
}

sub _overlay {
    my ($self, $base_dir) = @_;

    my @overlay_opts = ();
    my $key = $self->_sub_entity('key');
    push(@overlay_opts, key => $key) if ($key);

    return Template::Overlay->new($base_dir, 
        $self->_resolver(), @overlay_opts)
}

sub _resolver {
    my ($self) = @_;

    my @resolver_opts = ();
    my $os = $self->_sub_entity('os');
    push(@resolver_opts, os => $os) if ($os);

    my $resolver_coordinate = $self->_sub_entity('resolver_coordinate');
    my $resolver_spec = $resolver_coordinate
        ? $self->_entity($resolver_coordinate)
        : $self->_entity();
    return Template::Resolver->new($resolver_spec, @resolver_opts);
}

sub update {
    my ($self) = @_;
    $self->_local_template_with_base_and_template(
        sub {
            my ($base_dir, $template_dir, $to_dir) = @_;
            $logger->tracef("update to=[%s], template=[%s]", $to_dir, $template_dir);
            $self->_overlay($to_dir)->overlay($template_dir);
        });
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

=constructor new($entity, $coordinate)

Constructs a new overlay configured by C<$entities> at C<$coordinate>.  

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
Footprintless::Mixins
Template::Overlay
