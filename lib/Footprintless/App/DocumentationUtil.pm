use strict;
use warnings;

package Footprintless::App::DocumentationUtil;

# ABSTRACT: A utility class for generating help documentation from POD
# PODNAME: Footprintless::App::DocumentationUtil

use Exporter qw(import);
use File::Spec;
use Log::Any;

my $logger = Log::Any->get_logger();

our @EXPORT_OK = qw(
    abstract
    description
    examples
    pod_section
);

sub abstract {
    my ($self_or_class) = @_;

    my $pm_file = _pm_file($self_or_class);
    return '(unknown)' unless ($pm_file);

    require Footprintless::Util;
    return Footprintless::Util::slurp($pm_file) =~ /^#+\s*ABSTRACT: (.*)$/m
        ? $1 : '(unknown)';
}

sub description {
    return pod_section($_[0], 'DESCRIPTION', 0, qr/Description:\n/);
}

sub examples {
    return pod_section($_[0], 'EXAMPLES');
}

sub pod_section {
    my ($self_or_class, $section, $indent, $remove) = @_;

    my $pm_file = _pm_file($self_or_class) ||
        return $self_or_class->abstract();

    my $pod = '';
    open(my $output, '>', \$pod);

    require Pod::Usage;
    Pod::Usage::pod2usage( 
        -input => $pm_file,
        -output => $output,
        -exit => "NOEXIT", 
        -verbose => 99,
        -sections => $section,
        indent => $indent);

    if ($pod) {
        $pod =~ s/$remove//m if ($remove);
        chomp($pod);
    }

    return $pod;
}

sub _pm_file {
    my ($self_or_class) = @_;
    my $class = ref($self_or_class) || $self_or_class;

    my @pm_file_parts = split(/::/, $class);
    $pm_file_parts[$#pm_file_parts] .= '.pm';
    my $pm_file = File::Spec->catfile(@pm_file_parts);

    my $path = $INC{$pm_file};
    unless ($path) {
        foreach my $prefix (@INC) {
            my $prefix_path = File::Spec->catfile($prefix, $pm_file);
            if (-f $prefix_path) {
                $path = $prefix_path;
                last;
            }
        }
    }

    return $path;
}

1;

__END__

=export_ok abstract($self_or_class)

Returns the content of the C<ABSTRACT> section of the pod for 
C<$self_or_class>.

=export_ok description($self_or_class)

Returns the content of the C<DESCRIPTION> section of the pod for 
C<$self_or_class>.

=export_ok examples($self_or_class)

Returns the content of the C<EXAMPLES> section of the pod for 
C<$self_or_class>.

=export_ok pod_section($self_or_class, $section, $indent, $remove)

Returns the content of the C<$section> section of the pod for 
C<$self_or_class> with indent level C<$indent>.  If specified, 
C<$remove> a regex used to find content to remove.
