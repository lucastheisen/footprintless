use strict;
use warnings;

package Footprintless::Deployment;

# ABSTRACT: A deployment manager
# PODNAME: Footprintless::Deployment

use Carp;
use File::Path qw(
    make_path
);
use File::Temp;
use Footprintless::Command qw(
    batch_command
    cp_command
    mkdir_command
    rm_command
);;
use Footprintless::CommandOptionsFactory;
use Footprintless::Localhost;
use Footprintless::ResourceManager;
use Footprintless::Resource::UrlProvider;
use Footprintless::Util qw(
    agent
    rebase
    temp_dir
);
use Log::Any;

my $logger = Log::Any->get_logger();

sub new {
    return bless({}, shift)->_init(@_);
}

sub clean {
    my ($self, %options) = @_;

    Footprintless::Util::clean($self->{spec}{clean}, 
        command_runner => $self->{command_runner},
        command_options => $self->{command_options},
        rebase => $options{rebase});
}

sub deploy {
    my ($self, %options) = @_;
    my ($is_local, $to_dir);

    if ($options{rebase}) {
        $to_dir = rebase($self->{spec}{to_dir}, $options{rebase});
        $is_local = 1;
    }
    else {
        $is_local = $self->{localhost}->is_alias($self->{spec}{hostname});
        $to_dir = $is_local ? $self->{spec}{to_dir} : temp_dir();
    }

    my $resource_dir = $self->{spec}{resource_dir}
        ? File::Spec->catdir($to_dir, $self->{spec}{resource_dir})
        : $to_dir;
    make_path($resource_dir);

    my @names = $options{names}
        ? @{$options{names}}
        : keys(%{$self->{spec}{resources}});

    $logger->debugf("deploy %s to %s", \@names, $resource_dir);
    my $resource_manager = $self->{factory}->resource_manager();
    foreach my $name (@names) {
        my $resource_spec = $self->{spec}{resources}{$name};
        my $resource = $resource_manager->resource($resource_spec);
        croak("unknown resource $name") unless ($resource);

        my $to = ref($resource_spec) && $resource_spec->{as} 
            ? File::Spec->catfile($resource_dir, $resource_spec->{as})
            : $resource_dir;
        $logger->tracef("download %s to '%s'", $resource, $to);
        $resource_manager->download($resource, to => $to);
    }

    $self->_push_to_destination($to_dir, $options{status}) unless ($is_local);
    $logger->debug("deploy complete");
}

sub _init {
    my ($self, $factory, $coordinate, %options) = @_;
    $logger->tracef("coordinate=[%s]\noptions=[%s]",
        $coordinate, \%options);

    $self->{entity} = $factory->entities();
    $self->{spec} = $self->{entity}->get_entity($coordinate);

    $self->{factory} = $factory;
    $self->{localhost} = $factory->localhost();
    $self->{command_runner} = $factory->command_runner();
    $self->{command_options} = $factory->command_options(%{$self->{spec}});

    return $self;
}

sub _push_to_destination {
    my ($self, $temp_dir, $status) = @_;

    $logger->debug("pushing to destination");
    $self->{command_runner}->run_or_die(
        cp_command(
            $temp_dir, 
            $self->{spec}{to_dir}, 
            $self->{command_options},
            'status' => $status));
}

1;

__END__
=head1 SYNOPSIS

    # Standard way of getting a deployment
    use Footprintless;
    my $deployment = Footprintless->new()->deployment('deployment');

    # Standard deploy procedure
    $deployment->clean();
    $deployment->deploy();

    # Deploy to temp instead of the entity configured location
    my $rebase = {
        from => '/opt/tomcat', 
        to => '/tmp/tomcat'
    };
    $deployment->clean(rebase => $rebase);
    $deployment->deploy(rebase => $rebase);

    # Only deploy selected resources
    $deployment->deploy(names => ['bar']);

=head1 DESCRIPTION

Manages deployments.  A deployment is a set of files and directories that
are all associated with a single component.  For example, if you are using
tomcat, a deployment might refer to all of the webapps deployed to the 
container, and the folders and files that are I<NOT> part of the tomcat
container itself.  

=head1 ENTITIES

A simple deployment:

    deployment => {
        clean => ['/opt/app/'],
        resources => {
            foo => 'http://download.com/foo.exe',
            bar => 'http://download.com/bar.exe'
        },
        to_dir => '/opt/app'
    }

A more complex situation, perhaps a tomcat instance:

    deployment => {
        'Config::Entities::inherit' => ['hostname', 'sudo_username'],
        clean => [
            '/opt/tomcat/conf/Catalina/localhost/',
            '/opt/tomcat/temp/',
            '/opt/tomcat/webapps/',
            '/opt/tomcat/work/'
        ],
        resources => {
            bar => '/home/me/.m2/repository/com/pastdev/bar/1.2/bar-1.2.war',
            baz => {
                coordinate => 'com.pastdev:baz:war:1.0',
                'as' => 'foo.war',
                type => 'maven'
            }
        },
        to_dir => '/opt/tomcat/webapps'
    }

=constructor new($entity, $coordinate, %options)

Constructs a new deployment configured by C<$entities> at C<$coordinate>.  
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

The resource manager to use.  Defaults to an instance of 
L<Footprintless::ResourceManager> configured to use a 
L<Footprintless::MavenProvider> if L<Maven::Agent> is available, and a
L<Footprintless::UrlProvider> in that order.

=back

=method clean(%options)

Cleans the deployment.  Each path in the C<configuration.clean> entity, 
will be removed from the destination.  If the path ends in a C</>, then 
after being removed, the directory will be recreated.  The supported 
options are:

=over 4

=item rebase

A hash containing C<from> and C<to> where the paths for each item in the
clean entity will have the C<from> portion of their path substituted by 
C<to>.  For example, if the path is C</foo/bar> and rebase is
C<{from => '/foo', to => '/baz'}>, then the resulting path would be 
C</baz/bar>.

=back

=method deploy(%options)

Deploys all the resources listed in the C<resource> entity to the location
specified in the C<configuration.to_dir> entity. The supported options 
are:

=over 4

=item names

A list of names of resources that should be deployed.  If this option is
provided, any names not in this list will be ignored.

=item rebase

A hash containing C<from> and C<to> where the paths for each item in the
clean entity will have the C<from> portion of their path substituted by 
C<to>.  For example, if the path is C</foo/bar> and rebase is
C<{from => '/foo', to => '/baz'}>, then the resulting path would be 
C</baz/bar>.

=item status

If I<truthy>, then status information will be provided to the command 
runner.  In order for this information to be useful, the command runner
should be supplied with the C<{err_buffer => \*STDERR}> runner option
so that it will, in turn, be written to STDERR.  Also, status is 
implemented using the C<pv> command which I<MAY NOT> already be installed.
If it is missing, this option will cause the command itself to fail.

=back

=head1 SEE ALSO

Config::Entities
Footprintless
Footprintless::CommandOptionsFactory
Footprintless::CommandRunner
Footprintless::Localhost
Footprintless::ResourceManager

