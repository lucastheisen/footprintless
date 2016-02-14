use strict;
use warnings;

package Footprintless::App::Command::config;

use Footprintless::App -command;
use Log::Any;

my $logger = Log::Any->get_logger();

sub abstract {
    return 'prints the config at the coordinate';
}

sub description {
    return 'prints the contents of the config at the coordinate';
}

sub execute {
    my ($self, $opts, $args) = @_;

    my $config = $self->app()->footprintless()
        ->entities()->get_entity($args->[0]);

    my $string;
    my $format = $opts->{format} || 'dumper1';
    $logger->tracef('format=%s,config=%s', $format, $config);
    if ($format =~ /^dumper([0-3])?$/) {
        require Data::Dumper;
        my $indent = defined($1) ? $1 : 1;
        $string = Data::Dumper->new([$config])
            ->Indent($indent)
            ->Dump();
    }
    elsif ($format eq 'properties') {
        $self->usage_error("not yet implemented format [$format]");
    }
    elsif ($format =~ /^json([0-2])?$/) {
        require JSON;
        my $json = JSON->new();
        if (!defined($1) || $1 == 1) {
            $json->pretty();
        }
        if ($1 == 2) {
            $json->canonical(1);
        }
        $logger->tracef('json encode {{%s}}', $config);
        $string = $json->encode($config);
    }
    else {
        $self->usage_error("unsupported format [$format]");
    }

    print($string);
}

sub opt_spec {
    return (
        [ "format|f=s",  "format to print", {default => 'dumper1'} ],
    );
}

sub usage_desc { 
    return "fpl %o [COORDINATE]" 
}

sub validate_args {
    my ($self, $opt, $args) = @_;

    $self->usage_error("coordinate is required") unless @$args;
}

1;
