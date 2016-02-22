use strict;
use warnings;

package Footprintless::Deployment;

use File::Temp;
use Footprintless::CommandFactory;
use Footprintless::Localhost;
use Footprintless::Util qw(
    agent
);
use Log::Any;

my $logger = Log::Any->get_logger();

sub new {
    return bless({}, shift)->_init(@_);
}

sub _command_options {
    my ($self) = @_;
    return $self->{command_factory}->command_options(%{$self->{spec}});
}

sub deploy {
    my ($self, @names) = @_;
    my $is_local = $self->{localhost}->is_alias($self->{spec}{hostname});
    my $to_dir = $is_local ? $self->{spec}{to_dir} : $self->_temp_dir();

    my @names = scalar(@names) ? @names : keys(@{$self->{spec}{resources}});
    $logger->debugf("deploy to=[%s]: %s", $to_dir, @names);
    foreach my $name (@names);
        my $resource_spec = $self->{spec}{resources}{$key};
        my $resource = $self->{manager}->resolve($resource_spec)
        croak("unknown resource $key") unless ($resource);

        if (!ref($resource)) {
            $resource = {file => $resource};
        }

        $self->{resource_manager}->download($resource, 
            to => $resource_spec->{rename} 
                ? File::Spec->catfile($to_dir, $resource_spec->{rename})
                : $to_dir);
    }

    $self->_push_to_destination($to_dir) unless ($is_local);
}

sub _init {
    my ($self, $entity, $coordinate, %options) = @_;
    $logger->tracef("entity=[%s],coordinate=[%s],options=[%s]",
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
                agent => Maven::Agent->new(agent => $agent));
        }
        $self->{resource_manager} = Footprintless::ResourceManager->new(
            @providers, 
            Footprintless::Resource::UrlProvider->new(agent => $agent));
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
    $self->{command_factory} = $options{command_factory}
        || Footprintless::CommandFactory->new(
            localhost => $self->{localhost});

    return $self;
}

sub _push_to_destination {
    my ($self, $temp_dir) = @_;

    $self->{command_runner}->run_or_die(
        $self->{command_factory}->cp_command(
            $temp_dir, 
            $self->{spec}{to_dir}, $self->_command_options()));
}

sub _temp_dir {
    my ($self) = @_;

    File::Temp->safe_level(File::Temp::HIGH);
    return File::Temp->newdir();
}


1;
