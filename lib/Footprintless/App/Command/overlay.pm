use strict;
use warnings;

package Footprintless::App::Command::overlay;

use Footprintless::App -command;
use Log::Any;
use Template::Overlay;
use Template::Resolver;

my $logger = Log::Any->get_logger();

sub abstract {
    return 'performs actions on an overlay';
}

sub description {
    return 'performs actions on an overlay';
}

sub execute {
    my ($self, $opts, $args) = @_;
    my ($coordinate) = @$args;

    if ($opts->{log}) {
        $self->_configure_logging($opts->{log});
    }

    my $overlay = $self->app()->footprintless()->overlay($coordinate);

    if ($opts->{clean}) {
        $logger->info('Performing clean...');
        $overlay->clean();
    }
    elsif ($opts->{initialize}) {
        $logger->info('Performing initialize...');
        $overlay->initialize();
    }
    else {
        $logger->info('Performing update...');
        $overlay->update();
    }

    $logger->info('Done...');
}

sub _configure_logging {
    my ($self, $level) = @_;
    require Log::Any::Adapter;
    Log::Any::Adapter->set('Stderr', 
        log_level => Log::Any::Adapter::Util::numeric_level($level));
}

sub opt_spec {
    return (
        ["log=s", "will set the log level",],
        ["clean",  "will clean the overlay",],
        ["initialize",  "initialize the overlay",],
    );
}

sub usage_desc { 
    return "fpl %o <COORDINATE>";
}

sub validate_args {
    my ($self, $opts, $args) = @_;
    my ($coordinate) = @$args;

    $self->usage_error("coordinate is required") unless @$args;

    my $footprintless = $self->app()->footprintless();
    eval {
        $self->{overlay} = $self->app()->footprintless()->overlay($coordinate);
    };
    $self->usage_error("invalid coordinate [$coordinate]: $@") if ($@);
}

1;
