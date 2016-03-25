use strict;
use warnings;

package Footprintless::CommandOptionsFactory;

# ABSTRACT: A factory for creating command options
# PODNAME: Footprintless::CommandOptionsFactory

use Carp;
use Footprintless::Localhost;
use Footprintless::Command;

sub new {
    return bless({}, shift)->_init(@_);
}

sub command_options {
    my ($self, %options) = @_;

    $options{ssh} = $self->{default_ssh} unless ($options{ssh});
    delete($options{sudo_username}) unless ($options{sudo_username});
    delete($options{username}) unless ($options{username});
    if ($self->{localhost} && $options{hostname} &&
        $self->{localhost}->is_alias($options{hostname})) {
        delete($options{hostname});
    }

    return Footprintless::Command::command_options(%options);
}

sub _init {
    my ($self, %options) = @_;

    $self->{localhost} = $options{localhost}
        || Footprintless::Localhost->new()->load_all();
    $self->{default_ssh} = $options{default_ssh} || 'ssh -q';

    return $self;
}

1;
__END__
=head1 DESCRIPTION

This module creates 
L<command opitons|Footprintless::Command/command_options(%options)> that will use 
L<Footprintless::Localhost> to determine if the hostname in the options
is an alias for localhost.  If so, it will remove hostname from the
options to prevent network operations and allow for local implementation
optimizations.

=head1 ENTITIES

There are four entites that are used for command options.  All four have
scalar values.  Their defaults are:

    hostname => undef,
    ssh => 'ssh -q',
    sudo_username => undef,
    username => undef

Most (if not all) modules make use of these entities.

=constructor new(%options)

Constructs an instance of C<Footprintless::CommandOptionsFactory>.  The
supported options are:

=over 4

=item localhost

A preconfigured instance of C<Footprintless::Localhost>.  Defaults to
an instance with C<load_all()> called.

=item default_ssh

The default ssh command to use if not supplied in the C<%options> 
passed in to C<command_options(%options)>.  Defaults to C<ssh -q>.

=back

=method command_options(%options)

Removes C<hostname> from C<%options> if it is an alias for localhost, 
then forwards on to 
L<Fooptintless::Command::command_options|Footprintless::Command/command_options(%options)>.

=head1 SEE ALSO

Footprintless
Footprintless::Command
Footprintless::Localhost
