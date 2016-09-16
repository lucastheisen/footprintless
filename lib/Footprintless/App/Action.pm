use strict;
use warnings;

package Footprintless::App::Action;

# ABSTRACT: A base class for actions
# PODNAME: Footprintless::App::Action

use parent qw(App::Cmd::ArgProcessor);

use Footprintless::App -ignore;
use Log::Any;

my $logger = Log::Any->get_logger();

sub _new {
    my ($class, $self) = @_;
    return bless($self, $class);
}

sub abstract {
    my ($self_or_class) = @_;

    require Footprintless::App::DocumentationUtil;
    return Footprintless::App::DocumentationUtil::abstract($self_or_class);
}

sub description {
    my ($self_or_class) = @_;
    my $description = ucfirst($self_or_class->abstract());
    if (scalar($self_or_class->opt_spec())) {
        $description .= "\n\nAvailable options:\n";
    }
    return $description;
}

sub prepare {
    my ($class, $app, $footprintless, $coordinate, @args) = @_;

    my ($opts, $remaining_args, %fields) = $class->_process_args(
        \@args, $class->usage_desc(), $class->opt_spec());

    return (
        $class->_new({
            app => $app,
            footprintless => $footprintless,
            coordinate => $coordinate,
            %fields}),
        $opts,
        $remaining_args);
}

sub opt_spec {
    return ();
}

sub usage {
    return $_[0]->{usage};
}

sub usage_error {
    my ($self, $message, $coordinate) = @_;
    require Footprintless::App::UsageException;
    die(Footprintless::App::UsageException->new($message, $coordinate));
}

sub validate_args {}

1;

__END__

=func abstract($self_or_class) 

Returns the abstract for the action.  By default it will pull it from the
C<ABSTRACT> section of the pod.  This function should be called using
I<method invokation>.

=func description($self_or_class) 

Returns the description for the action.  By default it will pull it from the
C<DESCRIPTION> section of the pod.  This function should be called using
I<method invokation>.

=func opt_spec()

Returns an options specificatino for this action according to 
L<Getopt::Long::Descriptive>.

=func prepare($class, $app, $footprintless, $coordinate, @args)

Processes C<@args> to parse off the options, then generates a new instance
of the action implementation and returns the 3-tuple: action, options, 
remaining args.  See L<App::Cmd::Command::prepare> for inspiration.

=method execute($opts, $args)

Executes the action.

=method usage()

Returns the usage object from L<Getopt::Long::Descriptive> for the action.

=method usage_error($message, $coordinate)

Die's with a generated message based on C<$message> and C<$coordinate>.

=method usage_desc() 

Returns the top level usage line.  See L<App::Cmd::Command::usage_desc> for
inspiration.

=method validate_args($opts, $args)

Performs additional validation on C<$opts> and C<$args>.  Calls 
L<usage_error($message, $coordinate)> if there is a problem.

=for Pod::Coverage _new 

=head1 SEE ALSO

Footprintless::App::DocumentationUtil
