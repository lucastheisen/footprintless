use strict;
use warnings;

package Footprintless::App::Action;

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

=for Pod::Coverage new execute opt_spec usage_desc validate_args
