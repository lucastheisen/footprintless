use strict;
use warnings;

package Footprintless::ResourceManager;

# ABSTRACT: A manager for finding and retrieving resources
# PODNAME: Footprintless::ResourceManager

use Carp;
use Footprintless::Resource::Maven;
use Footprintless::Resource::Url;

sub new {
    return bless({}, shift)->_init(@_);
}

sub download {
    my ($self, $resource, @options) = @_;

    foreach my $provider (@{$self->{providers}}) {
        if ($provider->supports($resource)) {
            return $provider->download($resource, @options);
        }
    }

    croak("unsupported resource type [$resource]");
}

sub _init {
    my ($self, @providers) = @_;

    $self->{providers} = \@providers;
    
    return $self;
}

sub resource {
    my ($self, $spec) = @_;

    foreach my $provider (@{$self->{providers}}) {
        if ($provider->supports($spec)) {
            return $provider->resource($spec);
        }
    }

    croak("unsupported resource: $spec");
}

1;

__END__
=head1 SYNOPSIS

  use Footprintless;

  my $footprintless = Footprintless->new();
  my $resource_manager = footprintless->resource_manager();

  # Find a resource
  my $resource = $resource_manager->resource('/foo/bar');
  # Download it
  my $file = $resource->download();

  # Download a maven resource (without resolving first)
  my $file = $resource_manager->download('com.pastdev:foo:1.0.0');

  # Download a resource to a specific location
  $resource_manager->download(
      'http://pastdev.com/resources/baz', 
      to => '/foo/baz');

=head1 DESCRIPTION

Manages finding and retrieving resources.

=constructor new(@providers)

Constructs a C<Footprintless::ResourceManager> that will locate resources
using the supplied providers.  Each provider will by queried, in order,
with a call to 
L<supports($spec)|Footprintless::Resource::Provider/supports($spec)>.  The
first to respond with a I<truthy> value will be used.

=method download($resource, %options)

Downloads C<$resource>, and returns the path that it was downloaded to.
The supported options are:

=over 4

=item to

The path to download to.  If the path points to an existing directory, 
then the resource will be downloaded into that directory and maintain its 
name part from the URL.  Otherwise, the path will be used for the file.

=back

=method resource($spec)

Returns the L<Footprintless::Resource> indicated by C<$spec>.

=head1 SEE ALSO

Footprintless
Footprintless::Resource
Footprintless::Resource::Provider
