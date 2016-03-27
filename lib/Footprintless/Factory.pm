use strict;
use warnings;

package Footprintless::Factory;

# ABSTRACT: The default factory for footprintless modules
# PODNAME: Footprintless::Factory

use Carp;
use Footprintless::Util;
use Log::Any;

my $logger = Log::Any->get_logger();

sub new {
    return bless({}, shift)->_init(@_);
}

sub agent {
    my ($self) = @_;

    unless ($self->{agent}) {
        $self->{agent} = Footprintless::Util::agent();
    }

    return $self->{agent};
}

sub command_options_factory {
    my ($self) = @_;

    unless ($self->{command_options_factory}) {
        require Footprintless::CommandOptionsFactory;
        $self->{command_options_factory} = 
            Footprintless::CommandOptionsFactory->new(
                localhost => $self->localhost());
    }

    return $self->{command_factory};
}

sub command_runner {
    my ($self) = @_;

    unless ($self->{command_runner}) {
        require Footprintless::Util;
        $self->{command_runner} = Footprintless::Util::default_command_runner();
    }

    return $self->{command_runner};
}

sub deployment {
    my ($self, $coordinate, %options) = @_;

    require Footprintless::Deployment;
    return Footprintless::Deployment->new($self->{entities}, $coordinate,
        command_options_factory => $options{command_options_factory} 
            || $self->command_options_factory(),
        command_runner => $options{command_runner} 
            || $self->command_runner(),
        localhost => $options{localhost} 
            || $self->localhost(),
        resource_manager => $options{resource_manager} 
            || $self->resource_manager());
}

sub entities {
    return $_[0]->{entities};
}

sub _init {
    my ($self, $entities) = @_;
    
    $self->{entities} = $entities;

    return $self;
}

sub localhost {
    my ($self) = @_;

    unless ($self->{localhost}) {
        require Footprintless::Localhost;
        $self->{localhost} = Footprintless::Localhost->new()->load_all();
    }

    return $self->{localhost};
}

sub log {
    my ($self, $coordinate, %options) = @_;

    require Footprintless::Log;
    return Footprintless::Log->new(
        $self->{entities}, $coordinate,
        command_options_factory => $options{command_options_factory} 
            || $self->command_options_factory(),
        command_runner => $options{command_runner} 
            || $self->command_runner(),
        localhost => $options{localhost} 
            || $self->localhost());
}

sub overlay {
    my ($self, $coordinate, %options) = @_;

    require Footprintless::Overlay;
    return Footprintless::Overlay->new($self->{entities}, $coordinate,
        command_options_factory => $options{command_options_factory} 
            || $self->command_options_factory(),
        command_runner => $options{command_runner} 
            || $self->command_runner(),
        localhost => $options{localhost} 
            || $self->localhost(),
        resource_manager => $options{resource_manager} 
            || $self->resource_manager());
}

sub resource_manager {
    my ($self) = @_;
    
    unless ($self->{resource_manager}) {
        require Footprintless::ResourceManager;
        my @providers = ();
        my $agent = $self->agent();
        if (require Maven::Agent) {
            require Footprintless::Resource::MavenProvider;
            push(@providers, Footprintless::Resource::MavenProvider->new(
                Maven::Agent->new(agent => $agent)));
        }
        require Footprintless::Resource::UrlProvider;
        $self->{resource_manager} = Footprintless::ResourceManager->new(
            @providers, 
            Footprintless::Resource::UrlProvider->new($agent));
    }

    return $self->{resource_manager};
}

sub service {
    my ($self, $coordinate, %options) = @_;

    require Footprintless::Service;
    return Footprintless::Service->new($self->{entities}, $coordinate,
        command_options_factory => $options{command_options_factory} 
            || $self->command_options_factory(),
        command_runner => $options{command_runner} 
            || $self->command_runner(),
        localhost => $options{localhost} 
            || $self->localhost());
}

1;

__END__
=head1 DESCRIPTION

The default factory for footprintless modules.

=constructor new($entities)

Creates a new factory configured by C<$entities>.

=method agent()

Returns the L<agent|LWP::UserAgent> used by this instance. 

=method command_options_factory()

Returns the 
L<command_options_factory|Footprintless::CommandOptionsFactory> used by 
this instance.

=method command_runner()

Returns the L<command_runner|Footprintless::CommandRunner> used by 
this instance.

=method deployment($coordinate, %options)

Returns a new instance of L<Footprintless::Deployment> preconfigured to
operate on the deployment at C<$coordinate>.  Supported options are

=over 4

=item command_options_factory

A C<command_options_factory> to use instead of that which is supplied by
this footprintless instance.

=item command_runner

A C<command_runner> to use instead of that which is supplied by
this footprintless instance.

=item localhost

A C<localhost> to use instead of that which is supplied by
this footprintless instance.

=item resource_manager

A C<resource_manager> to use instead of that which is supplied by
this footprintless instance.

=back

=method entities()

Returns the L<Config::Entities> that were resolved by this footprintless
instance.

=method localhost()

Returns the L<localhost|Footprintless::Localhost> resolver used by 
this instance.

=method log($coordinate, %options)

Returns a new instance of L<Footprintless::Log> preconfigured to
operate on the log at C<$coordinate>.  Supported options are

=over 4

=item command_options_factory

A C<command_options_factory> to use instead of that which is supplied by
this footprintless instance.

=item command_runner

A C<command_runner> to use instead of that which is supplied by
this footprintless instance.

=item localhost

A C<localhost> to use instead of that which is supplied by
this footprintless instance.

=back

=method overlay($coordinate, %options)

Returns a new instance of L<Footprintless::Overlay> preconfigured to
operate on the overlay at C<$coordinate>.  Supported options are

=over 4

=item command_options_factory

A C<command_options_factory> to use instead of that which is supplied by
this footprintless instance.

=item command_runner

A C<command_runner> to use instead of that which is supplied by
this footprintless instance.

=item localhost

A C<localhost> to use instead of that which is supplied by
this footprintless instance.

=item resource_manager

A C<resource_manager> to use instead of that which is supplied by
this footprintless instance.

=back

=method resource_manager()

Returns the L<resource_manager|Footprintless::ResourcManager> used by 
this instance.

=method service($coordinate, %options)

Returns a new instance of L<Footprintless::Service> preconfigured to
operate on the service at C<$coordinate>.  Supported options are

=over 4

=item command_options_factory

A C<command_options_factory> to use instead of that which is supplied by
this footprintless instance.

=item command_runner

A C<command_runner> to use instead of that which is supplied by
this footprintless instance.

=item localhost

A C<localhost> to use instead of that which is supplied by
this footprintless instance.

=back

=head1 SEE ALSO

Footprintless
Footprintless::Deployment
Footprintless::Log
Footprintless::Overlay
Footprintless::Service

