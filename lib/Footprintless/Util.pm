use strict;
use warnings;

package Footprintless::Util;

use Exporter qw(import);
our @EXPORT_OK = qw(
    dumper
    slurp
    spurt
);

sub dumper {
    require Data::Dumper;
    my $dumper = Data::Dumper->new(\@_);
    $dumper->Indent(2);
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
