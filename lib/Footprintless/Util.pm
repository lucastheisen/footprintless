use strict;
use warnings;

package Footprintless::Util;

# ABSTRACT: A utility method package for common functionality in Footprintless
# PODNAME: Footprintless::Util

use Carp;
use Exporter qw(import);
use Log::Any;

our @EXPORT_OK = qw(
    agent
    clean
    default_command_runner
    dynamic_module_new
    dumper
    exit_due_to
    extract
    factory
    invalid_entity
    resource_manager
    rebase
    slurp
    spurt
    temp_dir
    temp_file
);

my $logger = Log::Any->get_logger();

sub agent {
    my (%options) = @_;

    require LWP::UserAgent;
    my $agent = LWP::UserAgent->new();
    $agent->env_proxy();

    $agent->timeout($options{timeout}) if (defined($options{timeout}));
    $agent->cookie_jar($options{cookie_jar}) if (defined($options{cookie_jar}));

    return $agent;
}

sub clean {
    my ($paths, %options) = @_;

    if ($paths && ref($paths) eq 'ARRAY' && scalar(@$paths)) {
        $logger->debugf("cleaning %s", $paths);
        my $command_runner = $options{command_runner} 
            || default_command_runner();

        my @all_paths = $options{rebase}
            ? map {rebase($_, $options{rebase})} @$paths
            : @$paths;
        my @dir_paths = map {($_ =~  /\/\s*$/) ? $_ : ()} @all_paths;

        require Footprintless::Command;
        eval {
            $command_runner->run_or_die(
                Footprintless::Command::batch_command(
                    Footprintless::Command::rm_command(@all_paths),
                    (@dir_paths 
                        ? Footprintless::Command::mkdir_command(@dir_paths)
                        : ()),
                    $options{command_options}));
        };
        if ($@) {
            $logger->errorf('clean failed: %s', $@);
            croak($@);
        }
    }
}

sub default_command_runner {
    require Footprintless::CommandRunner::IPCRun;
    return Footprintless::CommandRunner::IPCRun->new(@_);
}

sub dumper {
    require Data::Dumper;
    return Data::Dumper->new(\@_)
        ->Indent(1)
        ->Sortkeys(1)
        ->Dump();
}

sub dynamic_module_new {
    my ($module, @args) = @_;
    my $module_path = $module;
    $module_path =~ s/::/\//g;
    require "$module_path.pm"; ## no critic
    return $module->new(@args);
}

sub exit_due_to {
    my ($dollar_at, $verbose) = @_;
    if (ref($dollar_at) 
        && $dollar_at->isa(
            'Footprintless::CommandRunner::ExecutionException')) {
        $dollar_at->exit($verbose);
    }
    else {
        print(STDERR "$dollar_at\n");
        exit 255;
    }
}

sub extract {
    my ($archive, %options) = @_;

    my @to = $options{to} ? (to => $options{to}) : ();
    my @type = ();
    if ($options{type}) {
        push(@type, type => $options{type});
    }
    elsif ($archive =~ /\.war|\.jar|\.ear|\.twbx$/) {
        # other known zip type extensions
        push(@type, type => 'zip');
    }

    if (require Archive::Extract::Libarchive) {
        Archive::Extract::Libarchive
            ->new(archive => $archive, @type)
            ->extract(@to)
            || croak("unable to extract $archive: $!");
    }
    elsif (require Archive::Extract) {
        Archive::Extract
            ->new(archive => $archive, @type)
            ->extract(@to)
            || croak("unable to extract $archive: $!");
    }
    else {
        # todo: consider binary commands like unzip and tar 
        croak("extract requires either Archive::Extract::Libarchive or Archive::Extract");
    }
}

sub factory {
    my ($entities, @options) = @_;

    if (ref($entities) eq 'HASH') {
        require Config::Entities;
        $entities = Config::Entities->new({entity => $entities});
    }

    my $factory;
    my $factory_module = $entities->get_entity('footprintless.factory');
    if ($entities->get_entity('footprintless.factory')) {
        $factory = dynamic_module_new($factory_module, $entities, @options);
    }
    else {
        require Footprintless::Factory;
        $factory = Footprintless::Factory->new($entities, @options);
    }
    
    return $factory;
}

sub invalid_entity {
    my ($coordinate, $message) = @_;

    require Footprintless::InvalidEntityException;
    die(Footprintless::InvalidEntityException->new(
        $coordinate, $message || "$coordinate required"));
}

sub rebase {
    my ($path, $rebase) = @_;

    my $rebased;
    if ($path =~ /^$rebase->{from}(.*)$/) {
        $rebased = "$rebase->{to}$1";
    }
    else {
        croak("invalid rebase $path from $rebase->{from} to $rebase->{to}");
    }

    return $rebased;
}

sub resource_manager {
    my ($agent) = @_;
    $agent ||= agent();

    my @providers = ();
    if (require Maven::Agent) {
        require Footprintless::Resource::MavenProvider;
        push(@providers, Footprintless::Resource::MavenProvider->new(
            Maven::Agent->new(agent => $agent)));
    }

    require Footprintless::ResourceManager;
    require Footprintless::Resource::UrlProvider;
    return Footprintless::ResourceManager->new(
        @providers, 
        Footprintless::Resource::UrlProvider->new($agent));
}

sub slurp {
    my ($file) = @_;
    # http://www.perl.com/pub/2003/11/21/slurp.html
    return $file
        ? do {local(@ARGV, $/) = $file; <>}
        : do {local $/; <STDIN>};
}

sub spurt {
    my ($content, $file, %options) = @_;
    my $write_mode = $options{append} ? '>>' : '>';
    open(my $handle, $write_mode, $file)
        || croak("unable to open [$file]: $!");
    print($handle $content);
    close($handle);
}

sub temp_dir {
    require File::Temp;
    File::Temp->safe_level(File::Temp::HIGH());
    my $temp = File::Temp->newdir('fpl_XXXXXXXX', TMPDIR => 1);
    if (!chmod(0700, $temp)) {
        croak("unable to create secure temp file");
    }
    return $temp;
}

sub temp_file {
    require File::Temp;
    File::Temp->safe_level(File::Temp::HIGH());
    my $temp = File::Temp->new('fpl_XXXXXXXX', TMPDIR => 1);
    if (!chmod(0600, $temp)) {
        croak("unable to create secure temp file");
    }
    return $temp;
}

1;

__END__
=head1 SYNOPSIS

    use Footprintless::Util qw(
        agent
        clean
        default_command_runner
        dumper
        exit_due_to
        extract
        resource_manager
        slurp
        spurt
        temp_dir
    );    

    my $agent = agent();
    my $command_runner = default_command_runner();
    my $dumper = dumper();
    
    eval {
        $command_runner->run_or_die('cat /foo/bar');
    };
    exit_due_to($@) if ($@);    
    my $content = slurp('/foo/bar');
    spurt('baz', '/foo/bar', append => 1);

=head1 DESCRIPTION

This module contains common utility methods used by Footprintless.

=func agent(%options)

Returns a new L<agent|LWP::UserAgent>.  By default C<env_proxy> is set.
The supported options are:

=over 4

=item cookie_jar

A hashref for storing cookies.  If not supplied, cookies will be ignored.

=item timeout

The http request timeout.

=back

=func clean($paths, %options)

Removes all the entries in C<$paths> (must be an array ref).  If an entry ends
with a C</> it is assumed to be a directory, and will be recreated.

=func default_command_runner()

Returns a new instance of the default implementation of 
C<Footprintless::CommandRunner>.

=func dumper(@to_dump)

Prints a dump of C<@to_dump> using C<Data::Dumper> with C<Data::Dumper::Indent>
set to 1.

=func dynamic_module_new($module_name, @new_args)

Require's and creates a new instance of C<$module_name>, passing 
C<@new_args> to the C<new> method.

=func exit_due_to($reason, $verbose)

If C<$reason> is an instance of 
L<Footprintless::CommandRunner::ExecutionException>, C<$reason-E<gt>exit()> 
will be called.  Otherwise, C<$reason> will be printed to C<STDERR> and 
C<exit(255)> will be called.  The C<$verbose> argument will be passed on
thusly: C<$reason-E<gt>exit($verbose)>.

=func extract($archive, %options)

Will extract C<$archive>.  Will attempt to use L<Archive::Extract::Libarchive>
and if not found, will use L<Archive::Extract>.  The available options are:

=over 4

=item to

The location to extract to.  Defaults to L<cwd|Cwd/cwd>.

=item type

The type of the archive.  If not specified, the type will be inferred by
the file extension according to L<Lib::Archive>.  The following additional
extensions will be inferred as type C<zip>: C<ear>, C<jar>, C<twbx>, C<war>.

=back

=func factory($entities, %options)

Creates a new L<Footprintless::Factory>.  C<$entities> can be either, a
hashref, or a L<Config::Entities> object.  If a hashref, it will be 
used to create a new entities object, then passed along with options to
the C<Footprintless::Factory> constructor.

=func invalid_entity($message, $coordinate)

Dies with an instance of L<Footprintless::InvalidEntityException>.

=func rebase($path, \%rebase)

Replaces a portion of the start of C<$path>.  C<\%rebase> must have 2 keys,
C<from> and C<to>.  The C<from> value will be removed from C<$path> and
replaced with the C<to> value.

=func resource_manager($agent)

Returns a new instance of C<Footprintless::ResourceManager> configured with 
a L<maven provider|Footprintless::Resource::MavenProvider> if C<Maven::Agent> 
is available, and a L<url provider|Footprintless::Resource::UrlProvider> 
in that order.  If C<$agent> is provided, it will be passed on to the 
providers.

=func slurp([$file])

Reads the entire contents of C<$file> in one gulp.  If C<$file> is 
omitted, then it will read C<STDIN>.

=func spurt($content, $file, %options)

Writes C<$content> to C<$file>.  The available options are:

=func temp_file()

Creates a new temporary file with C<safe_level> set to 
C<HIGH>.  Returns the new L<File::Temp> object.

=func temp_dir()

Creates a new temporary directory with C<safe_level> set to 
C<HIGH>.  Returns the new L<File::Temp> object.

=over 4

=item append

If I<truthy>, C<$content> will be appended to C<$file> instead of overwriting.

=back
