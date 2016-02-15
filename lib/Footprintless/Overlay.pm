use strict;
use warnings;

package Footprintless::Overlay;

use File::Temp;
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
                $self->{command_factory}->batch_command(
                    $self->{command_factory}->rm_command(@$clean),
                    $self->{command_factory}->mkdir_command(@$clean),
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
    return $self->{command_factory}->command_options(%{$self->{spec}});
}

sub _init {
    my ($self, $entity, $coordinate, %options) = @_;
    $logger->tracef("entity=[%s],coordinate=[%s],options=[%s]",
        $entity, $coordinate, \%options);

    $self->{entity} = $entity;
    $self->{spec} = $entity->get_entity($coordinate);
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

sub initialize {
    my ($self) = @_;
    my $is_local = $self->{localhost}->is_alias($self->{spec}{hostname});
    my $to_dir = $is_local ? $self->{spec}{to_dir} : $self->_temp_dir();

    $self->clean();

    $self->_overlay($to_dir)
        ->overlay($self->{spec}{template_dir},
            to => $to_dir);

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
        $self->{command_factory}->cp_command(
            $temp_dir, 
            $self->{spec}{to_dir}, $self->_command_options()));
}

sub _resolver {
    my ($self) = @_;

    my @resolver_opts = ();
    if ($self->{spec}{os}) {
        push(@resolver_opts, os => $self->{spec}{os});
    }

    return Template::Resolver->new(
        $self->{spec}{resolver_coordinate}
            ? $self->{entity}->get_entity(
                $self->{spec}{resolver_coordinate})
            : $self->{spec},
        @resolver_opts),
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
