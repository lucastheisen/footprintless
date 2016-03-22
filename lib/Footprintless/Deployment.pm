use strict;
use warnings;

package Footprintless::Deployment;

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

    return unless ($self->{spec}{configuration}{clean} 
        && @{$self->{spec}{configuration}{clean}});

    my @clean;
    if ($options{rebase}) {
        @clean = map {$self->_rebase($_, $options{rebase})} 
            @{$self->{spec}{configuration}{clean}};
    }
    else {
        @clean = @{$self->{spec}{configuration}{clean}};
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
        $to_dir = $self->_rebase($self->{spec}{configuration}{to_dir}, 
            $options{rebase});
        $is_local = 1;
    }
    else {
        $is_local = $self->{localhost}->is_alias($self->{spec}{hostname});
        $to_dir = $is_local ? $self->{spec}{configuration}{to_dir} : $self->_temp_dir();
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
            $self->{spec}{configuration}{to_dir}, 
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
