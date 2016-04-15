use strict;
use warnings;

package Footprintless::Deployment;

# ABSTRACT: A deployment manager
# PODNAME: Footprintless::Deployment

use Carp;
use File::Path qw(
    make_path
);
use Footprintless::Mixins qw (
    _clean
    _download
    _resource
    _sub_entity
);
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
    my ($self, @options) = @_;
    $self->_clean(@options);
}

sub deploy {
    my ($self, %options) = @_;

    if ($options{to_dir}) {
        $self->_deploy($options{to_dir});
    }
    else {
        $self->_local_template(
            sub {
                $self->_deploy(@_);
            },
            rebase => $options{rebase});
    }

    $logger->debug("deploy complete");
}

sub _deploy {
    my ($self, $to_dir, %options) = @_;
    my $resources = $self->_sub_entity('resources', 1);

    my @names = $options{names}
        ? @{$options{names}}
        : keys(%$resources);

    $logger->debugf("deploy %s to %s", \@names, $to_dir);
    $self->_download($resources->{$_}, $to_dir) foreach (@names);
}

sub _init {
    my ($self, $factory, $coordinate, %options) = @_;
    $logger->tracef("coordinate=[%s]\noptions=[%s]",
        $coordinate, \%options);

    $self->{factory} = $factory;
    $self->{coordinate} = $coordinate;

    return $self;
}

sub _local_template {
    my ($self, $local_work, @options) = @_;
    $self->Footprintless::Mixins::_local_template(
        sub {
            my ($to_dir) = @_;

            my $resource_dir = $self->_sub_entity('resource_dir');
            $to_dir = $resource_dir
                ? File::Spec->catdir($to_dir, $resource_dir)
                : $to_dir;
            make_path($to_dir);

            &$local_work($to_dir);
        },
        @options);
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

=constructor new($entity, $coordinate)

Constructs a new deployment configured by C<$entities> at C<$coordinate>.  

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

=back

=head1 SEE ALSO

Config::Entities
Footprintless
Footprintless::Mixins

