use strict;
use warnings;

package Footprintless::Util;

# ABSTRACT: A utility method package for common functionality in Footprintless
# PODNAME: Footprintless::Util

use Carp;
use Exporter qw(import);

our @EXPORT_OK = qw(
    agent
    default_command_runner
    dumper
    exit_due_to
    invalid_entity
    slurp
    spurt
);

sub agent {
    require LWP::UserAgent;
    my $agent = LWP::UserAgent->new();
    $agent->env_proxy();
    return $agent;
}

sub default_command_runner {
    require Footprintless::CommandRunner::IPCRun;
    return Footprintless::CommandRunner::IPCRun->new(@_);
}

sub dumper {
    require Data::Dumper;
    my $dumper = Data::Dumper->new(\@_);
    $dumper->Indent(1);
    return $dumper->Dump(@_);
}

sub exit_due_to {
    my ($dollar_at, $verbose) = @_;
    if (ref($dollar_at) 
        && $dollar_at->isa(
            'Footprintless::CommandRunner::ExecutionException')) {
        $@->exit($verbose);
    }
    else {
        print(STDERR "$@");
        exit 255;
    }
}

sub invalid_entity {
    require Footprintless::InvalidEntityException;
    die(Footprintless::InvalidEntityException->new(@_));
}

sub slurp {
    my ($file) = @_;
    # http://www.perl.com/pub/2003/11/21/slurp.html
    return do { local( @ARGV, $/ ) = $file; <> };
}

sub spurt {
    my ($content, $file, %options) = @_;
    my $write_mode = $options{append} ? '>>' : '>';
    open(my $handle, $write_mode, $file)
        || croak("unable to open [$file]: $!");
    print($handle $content);
    close($handle);
}

1;

__END__
=head1 SYNOPSIS

  use Footprintless::Util qw(
      agent
      default_command_runner
      dumper
      exit_due_to
      slurp
      spurt
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

=func agent()

Returns a new instance of C<LWP::UserAgent> configured with C<env_proxy>.

=func default_command_runner()

Returns a new instance of the default implementation of 
C<Footprintless::CommandRunner>.

=func dumper(@to_dump)

Prints a dump of C<@to_dump> using C<Data::Dumper> with C<Data::Dumper::Indent>
set to 1.

=func exit_due_to($reason, $verbose)

If C<$reason> is an instance of 
L<Footprintless::CommandRunner::ExecutionException>, C<$reason-E<gt>exit()> 
will be called.  Otherwise, C<$reason> will be printed to C<STDERR> and 
C<exit(255)> will be called.  The C<$verbose> argument will be passed on
thusly: C<$reason-E<gt>exit($verbose)>.

=fund invalid_entity($message, $coordinate)

Dies with an instance of L<Footprintless::InvalidEntityException>.

=func slurp($file)

Reads the entire contents of C<$file> in one gulp.

=func spurt($content, $file, %options)

Writes C<$content> to C<$file>.  The available options are:

=over 4

=item append

If I<truthy>, C<$content> will be appended to C<$file> instead of overwriting.

=back
