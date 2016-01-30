use strict;
use warnings;

package Footprintless::App;

use App::Cmd::Setup -app;
use File::Spec;

sub footprintless {
    my ($self) = @_;

    if (!defined($self->{footprintless})) {
        my $fpl_home = $ENV{FPL_HOME} 
            || File::Spec->catdir($ENV{HOME}, '.footprintless');
        my @config_dirs = $ENV{FPL_CONFIG_DIRS}
            ? _split_dirs($ENV{FPL_CONFIG_DIRS})
            : (File::Spec->catdir($fpl_home, 'config'));
        my @config_properties = $ENV{FPL_CONFIG_PROPS} 
            ? _split_dirs($ENV{FPL_CONFIG_PROPS})
            : File::Spec->catdir($fpl_home, 'properties.pl');

        require Footprintless;
        $self->{footprintless} = Footprintless->new(
            config_dirs => \@config_dirs,
            config_properties_file => \@config_properties);
    }

    return $self->{footprintless};
}

sub _split_dirs {
    my ($dirs_string) = @_;

    my @dirs = ();
    my $separator = ($^O eq 'MSWin32') ? ';' : ':';
    foreach my $dir (split(/$separator/, $dirs_string)) {
        $dir =~ s/^\s+//;
        $dir =~ s/\s+$//;
        push(@dirs, $dir);
    }

    return @dirs;
}

1;
