use strict;
use warnings;

package Footprintless::Resource::UrlProvider;

use parent qw(Footprintless::Resource::Provider);

use File::Temp;
use Footprintless::Resource::Url;
use URI;

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
        $file = Footprintless::Resource::UrlProvider::DownloadedFile->new();
    }

    $self->{agent}->get($resource->get_uri(), ':content_file' => "$file");
    
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

package Footprintless::Resource::UrlProvider::DownloadedFile;

# Wraps a temp file to hold a reference so as to keep the destructor from
# getting called.  It will provide the filename when used as a string.

use overload q{""} => 'filename', fallback => 1;

sub new {
    my $self = bless({}, shift);
    my $file = File::Temp->new();

    $self->{handle} = $file;
    $self->{name} = $file->filename();

    return $self;
}

sub filename {
    return $_[0]->{name};
}


1;

__END__
