use strict;
use warnings;

package Footprintless::Test::Util;

use Carp;
use Cwd qw(abs_path);
use Exporter qw(import);
use File::Basename;
use File::Temp;
use Footprintless::Command qw(
    batch_command
    cp_command
    mkdir_command
);
use Footprintless::CommandRunner::IPCRun;
use Footprintless::CommandRunner::IPCRun3;
use Footprintless::Util qw(
    agent
);

our @EXPORT_OK = qw(
    command_runner
    lwp
    maven_agent
);


my $test_dir = abs_path(
    File::Spec->catfile(dirname(__FILE__), '..', '..', '..'));
my $default_maven_user_home = File::Spec->catfile(
    $test_dir, 'data', 'maven', 'HOME');

sub command_runner {
    my ($name) = shift || 'IPCRun';
    return "Footprintless::CommandRunner::$name"->new();
}

sub maven_agent {
    my ($dir) = @_;

    require Maven::Agent || croak('Maven::Agent not installed');

    my $maven_user_home;
    if ($dir) {
        $maven_user_home = File::Spec->catdir($dir, 'HOME');
        command_runner()->run_or_die(batch_command(
            mkdir_command($maven_user_home),
            cp_command($default_maven_user_home, $maven_user_home)));
    }
    else {
        $maven_user_home = $default_maven_user_home;
    }

    return Maven::Agent->new(
        agent => agent(),
        'user.home' => $maven_user_home);
}

1;
