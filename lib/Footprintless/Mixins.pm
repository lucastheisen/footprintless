use strict;
use warnings;

package Footprintless::Mixins;

# ABSTRACT: A utility package for mixins for standard object
# PODNAME: Footprintless::Mixins

use Carp;
use Exporter qw(import);
use File::Path qw(
    make_path
);
use Footprintless::Command qw(
    cp_command
);
use Footprintless::Util qw(
    extract
    invalid_entity
    temp_dir
);
use Log::Any;

our @EXPORT_OK = qw(
    _deployment
    _download
    _entity
    _overlay
    _push_resource_to_destination
    _push_to_destination
    _sub_coordinate
);

my $logger = Log::Any->get_logger();

sub _deployment {
    my ($self, $sub_coordinate, $name) = @_;
    my $deployment = $name ? $self->{$name} : undef;
    unless ($deployment) {
        $deployment = $self->{factory}
            ->deployment($self->_sub_coordinate($sub_coordinate));
        $self->{$name} = $deployment if ($name);
    }
    return $deployment;
}

sub _download {
    my ($self, $resource, $to) = @_;
    return $self->{factory}->resource_manager()
        ->download($resource, ($to ? (to => $to) : ()));
}

sub _entity {
    my ($self, $sub_coordinate, $required) = @_;
    my $entity = $self->{factory}->entities()
        ->get_entity($self->_sub_coordinate($sub_coordinate));
    invalid_entity("$sub_coordinate required") if ($required && !$entity);
    return $entity
}

sub _overlay {
    my ($self, $sub_coordinate, $name) = @_;
    my $overlay = $name ? $self->{$name} : undef;
    unless ($overlay) {
        $overlay = $self->{factory}
            ->overlay($self->_sub_coordinate($sub_coordinate));
        $self->{$name} = $overlay if ($name);
    }
    return $overlay;
}

sub _push_resource_to_destination {
    my ($self, $resource, $destination_dir, %options) = @_;
    
    my $temp_dir = temp_dir();
    if ($options{extract}) {
        extract($self->_download($resource), to => $temp_dir);
    }
    else {
        $self->_download($resource, $temp_dir);
    }

    $self->_push_to_destination($temp_dir, $destination_dir, %options);
}

sub _push_to_destination {
    my ($self, $source_dir, $destination_dir, %options) = @_;

    my %copy_options = ();
    my %runner_options = ();

    if ($options{status}) {
        $copy_options{status} = $options{status};
        $runner_options{err_handle} = \*STDERR;
    }

    $self->{command_runner}->run_or_die(
        cp_command(
            $source_dir,
            $destination_dir,
            $self->{command_options},
            %copy_options),
        \%runner_options);
}

sub _sub_coordinate {
    my ($self, $sub_coordinate) = @_;
    return "$self->{coordinate}.$sub_coordinate";
}

1;

__END__
=head1 DESCRIPTION

This class is NOT to be used directly.  It can be used by any class which has 
at minimum: 

    $self->{coordinate}
    $self->{factory}

The including class should:

    use Exporter qw(
        _coordinate
        _deployment
        ...
    );

Any methods they want to make use of.  It is important to note that these
methods may have interdependencies on each other, so care should be taken
until I have the time to figure out how to ensure proper inclusions.

=export_ok _deployment($sub_coordinate, [$name])

Returns a C<deployment> from the factory.  If C<$name> is supplied, the
C<deployment> will be a singleton stored at C<$self->{$name}>.

Requires L<_sub_coordinate|/_sub_coordinate($sub_coordinate)>

=export_ok _download($resource, [$to])

Downloads C<$resource> and returns the path to the downloaded file.  If
C<$to> is specified, the file will be downloaded to C<$to>.

=export_ok _entity($sub_coordinate, [$required])

Returns the descendent entity located at C<$sub_coordinate>.  If C<$required>
is truthy, and the entity does not exist, an 
L<InvalidEntityException|Footprintless::InvalidEntityException> is thrown.

Requires L<_sub_coordinate|/_sub_coordinate($sub_coordinate)>

=export_ok _overlay($sub_coordinate, [$name])

Returns a C<overlay> from the factory.  If C<$name> is supplied, the
C<overlay> will be a singleton stored at C<$self->{$name}>.

Requires L<_sub_coordinate|/_sub_coordinate($sub_coordinate)>

=export_ok _push_resource_to_destination($source, $destination, [%options])

Pushes C<$source> to C<$destination>.  Supported options are:

=over 4

=item extract

If truthy, then the resource will be extracted using 
L<extract|Footprintless::Util/extract($archive, %options)> before getting 
pushed to C<$destination>.

=item status

If truthy, then a status indicator will be printed to C<STDERR> 
(uses the C<pv> command).

=back

=export_ok _push_to_destination($source, $destination, [%options])

Pushes C<$source> to C<$destination>.  Supported options are:

=over 4

=item status

If truthy, then a status indicator will be printed to C<STDERR> 
(uses the C<pv> command).

=back

=export_ok _sub_coordinate($sub_coordinate)

Returns the coordinate of the descendent at C<$sub_coordinate>.
