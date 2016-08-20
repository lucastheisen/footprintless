use strict;
use warnings;

package Footprintless::Resource::UrlProvider;

# ABSTRACT: A resource provider for resources retrieved by URL
# PODNAME: Footprintless::Resource::UrlProvider

use parent qw(Footprintless::Resource::Provider);

use Carp;
use Footprintless::Resource::Url;
use Footprintless::Util qw(
    temp_file
);
use Log::Any;
use URI;

my $logger = Log::Any->get_logger();

sub _download {
    my ($self, $resource, %options) = @_;

    my $file;
    if ($options{to}) {
        $file = $options{to};
        if (-d $file) {
            my @segments = $resource->get_uri()->path_segments();
            $file = File::Spec->catfile($file, $segments[$#segments]);
        }
    }
    else {
        my @suffix;
        if ($resource->get_url() =~ /.*(\.\S*)$/) {
            $logger->tracef('preserving extension [%s] for resource %s',
                $1, $resource);
            push(@suffix, suffix => $1);
        }

        $file = temp_file(@suffix);
    }

    my $response = $self->{agent}->get($resource->get_uri(), 
        ':content_file' => "$file");
    croak('download failed: ', $response->message())
        unless ($response->is_success());
    
    return $file;
}

sub _init {
    my ($self, $agent) = @_;

    $self->Footprintless::Resource::Provider::_init();

    $self->{agent} = $agent;

    return $self;
}

sub resource {
    my ($self, $spec) = @_;

    return $spec if (UNIVERSAL::isa($spec, 'Footprintless::Resource::Url'));

    return Footprintless::Resource::Url->new(ref($spec) ? $spec->{url} : $spec);
}

sub supports {
    my ($self, $resource) = @_;

    return 1;
} 

1;

__END__
=constructor new($agent)

Creates a new C<Footprintless::Resource::UrlProvider> that will use 
C<$agent> to retrieve the resources.  C<$agent> should be an instance of
C<LWP::UserAgent>.

=method download($resource, \%options)

Downloads C<$resource> and returns the filename it downloaded to.  The
returned filename may be an object which overrides the C<""> operator so
that when used in string context, you will get the actual filename.  The
supported options are:

=over 4

=item to

The path of a directory or filename to download to.

=back

=method resource($spec)

Returns the C<Footprintless::Resource::Url> indicated by C<$spec>.

=method supports($spec)

Returns C<1>.  This provider will attempt to support any spec string.  If
C<$spec> is missing the scheme part, it will be set to C<file://>.  For
example, C</foo/bar> would result in the URL C<file:///foo/bar>.

=head1 SEE ALSO

Footprintless::Resource::Provider
Footprintless::Resource::Url
Footprintless::ResourceManager
Footprintless
URI
