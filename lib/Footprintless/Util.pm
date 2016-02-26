use strict;
use warnings;

package Footprintless::Util;

use Exporter qw(import);
our @EXPORT_OK = qw(
    agent
    default_command_runner
    dumper
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
