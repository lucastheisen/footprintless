use strict;
use warnings;

package Footprintless::Test::Resource::MavenProvider;

use parent qw(Footprintless::Resource::MavenProvider);

use File::Spec;
use Footprintless::Test::Util qw(
    copy_recursive
    test_dir
);
use Footprintless::Util qw(
    temp_dir
);


sub _init {
    my ($self, %options) = @_;

    require Maven::Agent || croak('Maven::Agent not installed');

    my $maven_user_home = File::Spec->catdir(temp_dir(), 'HOME');
    copy_recursive(test_dir('data', 'maven', 'HOME'), $maven_user_home);

    $self->{maven_agent} =  Maven::Agent->new(
        agent => $self->{factory}->agent(),
        'user.home' => $maven_user_home);

    return $self;
}

1;
