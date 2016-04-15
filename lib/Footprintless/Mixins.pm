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
    clean
    extract
    invalid_entity
    rebase
    temp_dir
);
use Log::Any;

our @EXPORT_OK = qw(
    _clean
    _command_options
    _deployment
    _download
    _entity
    _is_local
    _local_template
    _overlay
    _push_resource_to_destination
    _push_to_destination
    _resource
    _run
    _run_or_die
    _service
    _sub_coordinate
    _sub_entity
    _verify_required_entities
);

my $logger = Log::Any->get_logger();

sub _clean {
    my ($self, %options) = @_;
    my $clean = _sub_entity($self, 'clean');
    if ($clean) {
        clean($clean,
            command_runner => $self->{factory}->command_runner(),
            command_options => _command_options($self),
            rebase => $options{rebase});
    }
}

sub _command_options {
    my ($self, $sub_coordinate) = @_;
    my $entity = $sub_coordinate
        ? _sub_entity($self, $sub_coordinate)
        : _entity($self, $self->{coordinate});
    return $self->{factory}->command_options(%$entity);
}

sub _deployment {
    my ($self, $sub_coordinate, $name) = @_;
    my $deployment = $name ? $self->{$name} : undef;
    unless ($deployment) {
        $deployment = $self->{factory}
            ->deployment(_sub_coordinate($self, $sub_coordinate));
        $self->{$name} = $deployment if ($name);
    }
    return $deployment;
}

sub _download {
    my ($self, $resource, $to) = @_;
    my @options = $to && ref($resource) && $resource->{as} 
        ? (to => File::Spec->catfile($to, $resource->{as}))
        : (to => $to);
    return $self->{factory}->resource_manager()->download($resource, @options);
}

sub _entity {
    my ($self, $coordinate, $required) = @_;
    my $entity = $self->{factory}->entities()->get_entity($coordinate);
    invalid_entity($coordinate, "$coordinate required") 
        if ($required && !$entity);
    return $entity
}

sub _extract_resource {
    my ($self, $resource, $to_dir) = @_;
    extract(_download($self, $resource), to => $to_dir);
}

sub _is_local {
    my ($self, $hostname_sub_coordinate) = @_;
    return $self->{factory}->localhost()->is_alias(
        _sub_entity($self, $hostname_sub_coordinate));
}

sub _local_template {
    my ($self, $local_work, %options) = @_;
    my $dest_dir = _sub_entity($self, 'to_dir', 1);

    my ($is_local, $to_dir);
    if ($options{rebase}) {
        $to_dir = rebase($dest_dir, $options{rebase});
        $is_local = 1;
    }
    else {
        $is_local = _is_local($self, 'hostname');
        $to_dir = $is_local ? $dest_dir : temp_dir();
    }

    &$local_work($to_dir);

    _push_to_destination($self, $to_dir, $dest_dir) unless ($is_local);
}

sub _overlay {
    my ($self, $sub_coordinate, $name) = @_;
    my $overlay = $name ? $self->{$name} : undef;
    unless ($overlay) {
        $overlay = $self->{factory}
            ->overlay(_sub_coordinate($self, $sub_coordinate));
        $self->{$name} = $overlay if ($name);
    }
    return $overlay;
}

sub _push_resource_to_destination {
    my ($self, $resource, $destination_dir, %options) = @_;
    
    my $temp_dir = temp_dir();
    if ($options{extract}) {
        _extract_resource($self, $resource, $temp_dir);
    }
    else {
        _download($self, $resource, $temp_dir);
    }

    _push_to_destination($self, $temp_dir, $destination_dir, %options);
}

sub _push_to_destination {
    my ($self, $source_dir, $destination_dir, %options) = @_;

    my %copy_options = ();
    my %runner_options = ();

    if ($options{status}) {
        $copy_options{status} = $options{status};
        $runner_options{err_handle} = \*STDERR;
    }

    _run_or_die($self,
        cp_command(
            $source_dir,
            $destination_dir,
            $options{command_options} || _command_options($self),
            %copy_options),
        \%runner_options);
}

sub _resource {
    my ($self, $resource) = @_;
    return $self->{factory}->resource_manager()->resource($resource);
}

sub _run {
    my ($self, $command, @runner_options) = @_;
    return $self->{factory}->command_runner()->run($command, @runner_options);
}

sub _run_or_die {
    my ($self, $command, @runner_options) = @_;
    return $self->{factory}->command_runner()->run_or_die($command, @runner_options);
}

sub _service {
    my ($self, $sub_coordinate, $name) = @_;
    my $service = $name ? $self->{$name} : undef;
    unless ($service) {
        $service = $self->{factory}
            ->service(_sub_coordinate($self, $sub_coordinate));
        $self->{$name} = $service if ($name);
    }
    return $service;
}

sub _sub_coordinate {
    my ($self, $sub_coordinate) = @_;
    return "$self->{coordinate}.$sub_coordinate";
}

sub _sub_entity {
    my ($self, $sub_coordinate, $required) = @_;
    return _entity($self, _sub_coordinate($self, $sub_coordinate), $required);
}

sub _verify_required_entities {
    my ($self, @sub_coordinates) = @_;
    _sub_entity($self, $_, 1) foreach @sub_coordinates;
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
        _sub_coordinate
        _deployment
        ...
    );

=export_ok _command_options([$sub_coordinate])

Returns C<command_options>.  If C<$sub_coordinate> is supplied, it will be
used as the base spec, otherwise, this C<$self-E<lt>{coordinate}> will be used.

=export_ok _deployment($sub_coordinate, [$name])

Returns a C<deployment> from the factory.  If C<$name> is supplied, the
C<deployment> will be a singleton stored at C<$self->{$name}>.

=export_ok _download($resource, [$to])

Downloads C<$resource> and returns the path to the downloaded file.  If
C<$to> is specified, the file will be downloaded to C<$to>.

=export_ok _entity($coordinate, [$required])

Returns the entity located at C<$coordinate>.  If C<$required>
is truthy, and the entity does not exist, an 
L<InvalidEntityException|Footprintless::InvalidEntityException> is thrown.

=export_ok _is_local($hostname_sub_coordinate)

Returns a truthy value if the value at C<$hostname_sub_coordinate> is an
alias for the local system.

=export_ok _local_template(\&local_work, [%options])

Will check if the entity at C<$self-E<gt>{coordinate}> has a C<hostname> that
is local, and if not, it will create a temp directory, call C<&local_work> 
with that directory, and call 
L<_push_to_destination/_push_to_destination($source, $destination, [%options])>
with the temp directory as the source, and C<to_dir> as the destination when 
complete.  If C<hostname> is I<not> local, then C<&local_work> is called
with C<to_dir>.

=export_ok _overlay($sub_coordinate, [$name])

Returns a C<overlay> from the factory.  If C<$name> is supplied, the
C<overlay> will be a singleton stored at C<$self->{$name}>.

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

=export_ok _resolve($resource)

Resolves C<$resource>.

=export_ok _service($sub_coordinate, [$name])

Returns a C<service> from the factory.  If C<$name> is supplied, the
C<service> will be a singleton stored at C<$self->{$name}>.

=export_ok _sub_coordinate($sub_coordinate)

Returns the coordinate of the descendent at C<$sub_coordinate>.

=export_ok _sub_entity($sub_coordinate, [$required])

Returns the descendent entity located at C<$sub_coordinate>.  If C<$required>
is truthy, and the entity does not exist, an 
L<InvalidEntityException|Footprintless::InvalidEntityException> is thrown.

=export_ok _verify_required_entities(@sub_coordinates)

Will throw an L<InvalidEntityException|Footprintless::InvalidEntityException>
if any of C<@sub_coordinates> refer to entities that do not exist.
