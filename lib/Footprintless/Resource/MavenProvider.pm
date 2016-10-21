use strict;
use warnings;

package Footprintless::Resource::MavenProvider;

# ABSTRACT: A resource provider for resources retrieved by maven coordinate
# PODNAME: Footprintless::Resource::MavenProvider

use parent qw(Footprintless::Resource::Provider);

use Maven::Agent;

sub _download {
    my ($self, $resource, %options) = @_;
    return $self->{maven_agent}->download($resource->get_artifact(), %options);
}

sub _init {
    my ($self, %options) = @_;

    $self->{maven_agent} = Maven::Agent->new(
        agent => $self->{factory}->agent());

    return $self;
}

sub resource {
    my ($self, $spec) = @_;

    return $spec if (UNIVERSAL::isa($spec, 'Footprintless::Resource::Maven'));

    return Footprintless::Resource::Maven->new(
        $self->{maven_agent}->resolve_or_die(
            ref($spec) ? $spec->{coordinate} : $spec));
}

sub supports {
    my ($self, $resource) = @_;

    return 1 if (UNIVERSAL::isa($resource, 'Footprintless::Resource::Maven'));

    my $ref = ref($resource);
    if ($ref) {
        return 1 if ($resource->{coordinate});
    }
    elsif ($resource =~ /^(?:[^:]+:){2,4}[^:]+$/) {
        return 1;
    }

    return 0; 
}

1;

__END__
=method download($resource, \%options)

Downloads C<$resource> and returns the filename it downloaded to.  If 
using C<Maven::MvnAgent>, the resource will be cached in the local C<.m2>
repository.  All options are passed through to 
C<$maven_agent-E<gt>download()>.

=method resource($spec)

Returns the C<Footprintless::Resource::Maven> indicated by C<$spec>.

=method supports($spec)

Returns C<1> if C<$resource> is a hash ref containing an entry for 
C<coordinate>, or if C<$resource> is a string in the form of a maven 
coordinate (ex: groupId:artifactId:[packaging]:[classifier]:version).

=head1 SEE ALSO

Footprintless::Resource::Maven
Footprintless::Resource::Provider
Footprintless::ResourceManager
Footprintless
Maven::Agent
Maven::MvnAgent
