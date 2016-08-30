use strict;
use warnings;

package Footprintless::App::Command;

# ABSTRACT: The base command class for fpl commands
# PODNAME: Footprintless::App::Command

use parent qw(App::Cmd::Command);

sub description {
    return $_[0]->_pod('OPTIONS', 'ACTIONS');
}

sub _pod {
    my ($class, @sections) = @_;
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
        -sections => \@sections,
        #indent => 0
    );
    $descr =~ s/Description:\n//mg;
    chomp $descr;

    return $descr;
}

sub leader_text {
    return $_[0]->usage_desc() . "\n\n" . $_[0]->_pod('DESCRIPTION');
}

sub usage {
    my ($self) = @_;
    return $self; 
}

sub usage_error {
    my ($self, $error) = @_;
    die("Error: $error\n\n" . $self->leader_text());
}

1;
