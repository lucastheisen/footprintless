use strict;
use warnings;

package Footprintless::App::Command::overlay;

use Footprintless::App -command;
use Log::Any;
use Template::Overlay;
use Template::Resolver;

my $logger = Log::Any->get_logger();

sub abstract {
    return 'performs an overlay';
}

sub description {
    return 'performs an overlay';
}

sub execute {
    my ($self, $opts, $args) = @_;
    my ($coordinate) = @$args;

    my $config = $self->{config};

    my @overlay_opts = ();
    if ($config->{key}) {
        push(@overlay_opts, key => $config->{key});
    }

    my @resolver_opts = ();
    if ($config->{os}) {
        push(@resolver_opts, os => $config->{os});
    }
    
    my $overlay = Template::Overlay->new(
        $self->{overlay_base_dir},
        Template::Resolver->new(
            $config->{resolver_coordinate}
                ? $self->app()->footprintless()->get_config(
                    $config->{resolver_coordinate})
                : $config,
            @resolver_opts),
        @overlay_opts);

    if ($opts->{clean} && $config->{clean}) {
        $logger->info('Cleaning...');
    }

    $logger->info('Performing overlay...');
    $overlay->overlay($self->{overlay_template_dir},
        to => $self->{overlay_to_dir});

    $logger->info('Done...');
}

sub opt_spec {
    return (
        ["clean",  "will clean before overlay",],
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
    $self->{config} = $footprintless->get_config($coordinate);
    $self->usage_error("invalid coordinate [$coordinate]") unless $self->{config};
    $self->{overlay_base_dir} = $self->{config}{base_dir};
    $self->usage_error("overlay missing base_dir") unless $self->{overlay_base_dir};
    $self->{overlay_template_dir} = $self->{config}{template_dir};
    $self->usage_error("overlay missing template_dir") unless $self->{overlay_template_dir};
    $self->{overlay_to_dir} = $self->{config}{to_dir};
    $self->usage_error("overlay missing to_dir") unless $self->{overlay_to_dir};

    $self->{overlay_resolver_coordinate} = $self->{config}{resolver_coordinate}
        || $coordinate;
}

1;
