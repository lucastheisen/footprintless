use strict;
use warnings;

package Footprintless::Overlay;

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
