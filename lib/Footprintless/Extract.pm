use strict;
use warnings;

package Footprintless::Extract;

use Cwd;
use File::Path qw(make_path);
use File::Spec;

sub new {
    return bless({}, shift)->_init(@_);
}

sub extract {
    my ($self, %options) = @_;
    my $to = $options{to} || getcwd();

    my $current_dir = getcwd();
    eval {
        croak("$to is not a directory") if (-e $to && !-d $to);
        make_path($to);
        chdir($to);

        if ($self->{type} eq 'zip') {
            _unzip($self->{archive}, $to);
        }
        if ($self->{type} eq 'tar') {
            _untar($self->{archive}, $to);
        }
    };
    my $error = $@;
    chdir($current_dir);
    die($error) if ($error);
}

sub _init {
    my ($self, %options) = @_;

    $self->{archive} = $options{archive};
    
    my $dot_extension = $options{type} ? ".$options{type}" : $self->{archive};
    if ($dot_extension =~ /\.zip|\.war|\.jar|\.ear|\.twbx$/) {
        $self->{type} = 'zip';
    }
    elsif ($dot_extension =~ /\.tar|\.tar\.gz|\.tgz$/) {
        $self->{type} = 'tar';
    }
    else {
        croak("unknown archive type");
    }
    
    return $self;
}

sub _untar {
    my ($archive, $to) = @_;
    require Archive::Tar;
    Archive::Tar->new($archive)->extract();
}

sub _unzip {
    my ($archive, $to) = @_;
    require IO::Uncompress::Unzip;

    die 'Need a archive argument' unless defined $archive;
    $to = "." unless defined $to;

    my $u = IO::Uncompress::Unzip->new($archive)
        or die "Cannot open $archive: $IO::Uncompress::Unzip::UnzipError";

    my $status;
    for ($status = 1; $status > 0; $status = $u->nextStream()) {
        my $header = $u->getHeaderInfo();
        my (undef, $path, $name) = File::Spec->splitpath($header->{Name});
        my $destdir = "$to/$path";

        unless (-d $destdir) {
            make_path($destdir) or die "Couldn't mkdir $destdir: $!";
        }

        if ($name =~ m!/$!) {
            last if $status < 0;
            next;
        }

        my $destfile = "$to/$path/$name";
        my $buff;
        my $fh = IO::File->new($destfile, "w")
            or die "Couldn't write to $destfile: $!";
        while (($status = $u->read($buff)) > 0) {
            $fh->write($buff);
        }
        $fh->close();
        my $stored_time = $header->{'Time'};
        utime ($stored_time, $stored_time, $destfile)
            or die "Couldn't touch $destfile: $!";
    }

    die "Error processing $archive $!\n"
    if $status < 0 ;

    return;
}

1;
