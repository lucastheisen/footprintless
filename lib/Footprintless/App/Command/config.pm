use strict;
use warnings;

package Footprintless::App::Command::config;

# ABSTRACT: Prints the config at the coordinate.
# PODNAME: Footprintless::App::Command::config

use Footprintless::App -command;
use Log::Any;

my $logger = Log::Any->get_logger();

sub _entity_to_properties {
    my ($entity, $properties, $prefix) = @_;

    $properties = {} unless $properties;

    my $ref = ref($entity);
    if ($ref) {
        if ($ref eq 'SCALAR') {
            $properties->{$prefix} = $$entity;
        }
        elsif ( $ref eq 'ARRAY' ) {
            my $index = 0;
            foreach my $array_entity ( @{$entity} ) {
                _entity_to_properties( $array_entity, $properties,
                    ($prefix ? "$prefix\[$index\]" : "[$index]") );
                $index++;
            }
        }
        elsif ($ref =~ /^CODE|REF|GLOB|LVALUE|FORMAT|IO|VSTRING|Regexp$/) {
            croak( "unsupported ref type '$ref'" );
        }
        else { # HASH or blessed ref
            foreach my $key ( keys( %{$entity} ) ) {
                _entity_to_properties( $entity->{$key}, $properties,
                    ($prefix ? "$prefix.$key" : $key) );
            }
        }
    }
    else {
        $properties->{$prefix} = $entity;
    }

    return $properties;
}

sub execute {
    my ($self, $opts, $args) = @_;

    my $config = @$args
        ? $self->app()->footprintless()->entities()->get_entity($args->[0])
        : $self->app()->footprintless()->entities()->as_hashref();

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
        my $properties = _entity_to_properties($config);
        $string = join("\n", map {"$_=$properties->{$_}"} sort keys(%{$properties}));
    }
    elsif ($format =~ /^json([0-3])?$/) {
        require JSON;
        my $json = JSON->new();
        if (!defined($1) || $1 == 1 || $1 == 3) {
            $json->pretty();
        }
        if ($1 == 2 || $1 == 3) {
            $json->canonical(1);
        }
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
}

1;

__END__

=head1 SYNOPSIS

  fpl config project
  fpl config project.environment
  fpl config project.environment --format json2
  fpl config project --format dumper3

=head1 DESCRIPTION

Prints out the config at the specified coordinate.  The supported formats are:

    dumper      Same as dumper1
    dumper0     Perl Data::Dumper without newlines
    dumper1     Perl Data::Dumper with fixed indentation (2 spaces)
    dumper2     Perl Data::Dumper with dynamic indent
    dumper3     Perl Data::Dumper with dynamic indant and annotations
    json        Same as json1
    json0       Compact JSON
    json1       Pretty printed JSON
    json2       JSON with canonically sorted keys
    json3       Pretty printed JSON with canonically sorted keys
    properties  Java properties format alphabetically sorted (EXPERIMENTAL)

If no format is specified, dumper1 is implied.
