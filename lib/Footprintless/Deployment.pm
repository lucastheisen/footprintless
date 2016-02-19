use strict;
use warnings;

package Footprintless::Deployment;

use File::Temp;
use Footprintless::CommandFactory;
use Footprintless::Localhost;
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
    my ($self) = @_;
    my $is_local = $self->{localhost}->is_alias($self->{spec}{hostname});
    my $to_dir = $is_local ? $self->{spec}{to_dir} : $self->_temp_dir();

    $logger->tracef("deploy to=[%s], template=[%s]", $to_dir, $self->{spec}{template_dir});

    $self->_push_to_destination($to_dir) unless ($is_local);
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
