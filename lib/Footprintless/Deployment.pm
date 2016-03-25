use strict;
use warnings;

package Footprintless::Deployment;

# ABSTRACT: A deployment manager
# PODNAME: Footprintless::Deployment

use Carp;
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
);
use Log::Any;

my $logger = Log::Any->get_logger();

sub new {
    return bless({}, shift)->_init(@_);
}

sub clean {
    my ($self, %options) = @_;

    return unless ($self->{spec}{clean} 
        && @{$self->{spec}{clean}});

    my @clean;
    if ($options{rebase}) {
        @clean = map {$self->_rebase($_, $options{rebase})} 
            @{$self->{spec}{clean}};
    }
    else {
        @clean = @{$self->{spec}{clean}};
    }

    if (@clean) {
        $logger->debugf("cleaning deployment %s", \@clean);
        eval {
            $self->{command_runner}->run_or_die(
                batch_command(
                    rm_command(@clean),
                    mkdir_command(@clean),
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

sub deploy {
    my ($self, %options) = @_;
    my ($is_local, $to_dir);

    if ($options{rebase}) {
        $to_dir = $self->_rebase($self->{spec}{to_dir}, 
            $options{rebase});
        $is_local = 1;
    }
    else {
        $is_local = $self->{localhost}->is_alias($self->{spec}{hostname});
        $to_dir = $is_local ? $self->{spec}{to_dir} : $self->_temp_dir();
    }

    my @names = $options{names}
        ? @{$options{names}}
        : keys(%{$self->{spec}{resources}});

    $logger->debugf("deploy %s to %s", \@names, $to_dir);
    foreach my $name (@names) {
        my $resource_spec = $self->{spec}{resources}{$name};
        my $resource = $self->{resource_manager}->resource($resource_spec);
        croak("unknown resource $name") unless ($resource);

        if (!ref($resource)) {
            $resource = {file => $resource};
        }

        my $to = ref($resource_spec) && $resource_spec->{as} 
            ? File::Spec->catfile($to_dir, $resource_spec->{as})
            : $to_dir;
        $logger->tracef("download %s to '%s'", $resource, $to);
        $self->{resource_manager}->download($resource, to => $to);
    }
    $logger->debug("deploy complete");

    $self->_push_to_destination($to_dir, $options{status}) unless ($is_local);
}

sub _init {
    my ($self, $entity, $coordinate, %options) = @_;
    $logger->tracef("entity=[%s]\ncoordinate=[%s]\noptions=[%s]",
        $entity, $coordinate, \%options);

    $self->{entity} = $entity;
    $self->{spec} = $entity->get_entity($coordinate);
    if ($options{resource_manager}) {
        $self->{resource_manager} = $options{resource_manager};
    }
    else {
        my @providers = ();
        my $agent = $options{agent} || agent();
        if (require Maven::Agent) {
            require Footprintless::Resource::MavenProvider;
            push(@providers, Footprintless::Resource::MavenProvider->new(
                Maven::Agent->new(agent => $agent)));
        }
        $self->{resource_manager} = Footprintless::ResourceManager->new(
            @providers, 
            Footprintless::Resource::UrlProvider->new($agent));
    }
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

sub _push_to_destination {
    my ($self, $temp_dir, $status) = @_;

    $self->{command_runner}->run_or_die(
        cp_command(
            $temp_dir, 
            $self->{spec}{to_dir}, 
            $self->_command_options(),
            'status' => $status));
}

sub _rebase {
    my ($self, $path, $rebase) = @_;
    my $rebased;
    if ($path =~ /^$rebase->{from}(.*)$/) {
        $rebased = "$rebase->{to}$1";
    }
    else {
        croak("invalid rebase $path from $rebase->{from} to $rebase->{to}");
    }

    return $rebased;
}

sub _temp_dir {
    my ($self) = @_;

    File::Temp->safe_level(File::Temp::HIGH);
    return File::Temp->newdir();
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

