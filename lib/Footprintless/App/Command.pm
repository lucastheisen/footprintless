use strict;
use warnings;

package Footprintless::App::Command;

# ABSTRACT: The base command class for fpl commands
# PODNAME: Footprintless::App::Command

use parent qw(App::Cmd::Command);

sub description {
    my ($class) = @_;
    $class = ref $class if ref $class;
     
    #i classname to filename
    (my $pm_file = $class) =~ s!::!/!g;
    $pm_file .= '.pm';
    $pm_file = $INC{$pm_file} or return '';

    open my $input, "<", $pm_file or return '';

    my $descr = "";
    open my $output, ">", \$descr;

    require Pod::Usage;
    Pod::Usage::pod2usage( -input => $input,
        -output => $output,
        -exit => "NOEXIT", 
        -verbose => 99,
        -sections => ["DESCRIPTION", "COORDINATE", "ACTIONS"],
        #indent => 0
    );
    $descr =~ s/Description:\n//mg;
    chomp $descr;

    return $descr;
}

sub leader_text {
    return $_[0]->usage_desc();
}

sub usage {
    my ($self) = @_;
    return $self; 
}

1;
