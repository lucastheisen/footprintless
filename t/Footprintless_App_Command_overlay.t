use strict;
use warnings;

use App::Cmd::Tester;
use Data::Dumper;
use Footprintless;
use Footprintless::Util qw(slurp spurt);
use File::Basename;
use File::Path qw(make_path);
use File::Spec;
use File::Temp;
use Test::More tests => 21;

BEGIN {use_ok('Footprintless::App')}

eval {
    require Getopt::Long;
    Getopt::Long::Configure('pass_through', 'bundling');
    my $level = 'error';
    Getopt::Long::GetOptions(
        'log:s' => \$level
    );

    require Log::Any::Adapter;
    Log::Any::Adapter->set('+Footprintless::Test::Log::Any::Adapter::Handle', 
        handle => \*STDOUT,
        log_level => Log::Any::Adapter::Util::numeric_level($level));
};

my $logger = Log::Any->get_logger();
$logger->trace("All logging sent to stderr to avoid conflict with output");

my $test_dir = dirname(File::Spec->rel2abs($0));
my $base_bin_dir = File::Spec->catdir($test_dir, 'data', 'base', 'bin');
my $base_conf_dir = File::Spec->catdir($test_dir, 'data', 'base', 'conf');
my $expected_bin_dir = File::Spec->catdir($test_dir, 'data', 'expected', 'bin');
my $expected_conf_dir = File::Spec->catdir($test_dir, 'data', 'expected', 'conf');

sub footprintless {
    print("REMOVE ME: ", Dumper(\@_), "\n");
    my ($temp_dir, $overlay_coordinate, $entity_modifier) = @_;

    # Get the current entities
    $ENV{FPL_CONFIG_DIRS} = File::Spec->catdir($test_dir, 'config', 'entities');
    $ENV{FPL_CONFIG_PROPS} = File::Spec->catfile($test_dir, 'config', 'properties.pl')
        . (($^O eq 'MSWin32') ? ';' : ':')
        . File::Spec->catfile($test_dir, 'config', 'environment.pl');

    my $footprintless = Footprintless->new();
    my $overlay = $footprintless->entities()->get_entity($overlay_coordinate);
    unless ($overlay->{base_dir} eq File::Spec->catfile($test_dir, 'data', 'base')
        && $overlay->{template_dir} eq File::Spec->catfile($test_dir, 'data', 'template')) {
        $logger->errorf("%s=[%s]\n%s=[%s]",
            $overlay->{base_dir}, File::Spec->catfile($test_dir, 'data', 'base'),
            $overlay->{template_dir}, File::Spec->catfile($test_dir, 'data', 'template'));
        BAIL_OUT('environment configuration broken, could be dangerous to proceed...')
    }
    $logger->debug('environment looks good, proceed...');

    if ($entity_modifier) {
        # Now set up the test entities
        $logger->debug('modify entity configuration');
        my $entities_hashref = $footprintless->entities()->as_hashref();
        &$entity_modifier($entities_hashref);
        my $entities_dir = File::Spec->catdir($temp_dir, 'entities');
        make_path($entities_dir);
        for my $key (keys(%$entities_hashref)) {
            my $value = $entities_hashref->{$key};
            spurt('return '
                . Data::Dumper->new([$value], [$key])->Indent(1)->Dump(),
                File::Spec->catfile($entities_dir, "$key.pm"));
        }

        $ENV{FPL_CONFIG_DIRS} = File::Spec->catdir($entities_dir);
        delete $ENV{FPL_CONFIG_PROPS};

        $logger->debug('reloading footprintless with modified entities');
        $footprintless = Footprintless->new();
    }
    return $footprintless;
}

sub match {
    my ($file_name, $got_dir, $expected_dir) = @_;
    my $got_file = File::Spec->catfile($got_dir, $file_name);
    $logger->debugf('checking %s', $got_file);
    ok(-f $got_file, "$file_name is file");
    is(slurp($got_file), 
        slurp(File::Spec->catfile($expected_dir, $file_name)),
        "$file_name matches expected");
}

sub test_overlay {
    my ($action, $coordinate, %options) = @_;

    my $temp_dir = File::Temp->newdir();
    my $overlay_dir = File::Spec->catdir($temp_dir, 'overlay');
    my $to_dir = File::Spec->catdir($overlay_dir, 'to');
    my $to_bin_dir = File::Spec->catdir($to_dir, 'bin');
    my $to_conf_dir = File::Spec->catdir($to_dir, 'conf');
    make_path($to_bin_dir, $to_conf_dir);
    my $footprintless = footprintless($temp_dir, $coordinate,
        sub {
            my ($entities) = @_;
            my $overlay_entity = $entities;
            foreach my $part (split(/\./, $coordinate)) {
                $overlay_entity = $overlay_entity->{$part};
            }

            # convert to localhost and remove sudo_username to avoid ssh
            $overlay_entity->{hostname} = 'localhost';
            delete $overlay_entity->{sudo_username};

            # set to_dir to the temp directory
            $overlay_entity->{to_dir} = $to_dir;

            &{$options{entity_modifier}}($entities) if ($options{entity_modifier});
        });

    my $overlay = $footprintless->entities()->get_entity($coordinate);
    if ($logger->is_trace) {
        $logger->tracef('overlay: %s', Data::Dumper->new([$overlay])->Indent(1)->Dump());
    }
    is($overlay->{to_dir}, $to_dir, 'modified to dir');

    my $result = test_app('Footprintless::App' => [$action, $coordinate, 
            ($options{command_args} ? @{$options{command_args}} : ())]);
    if ($logger->is_debug()) {
        $logger->debugf("exit_code=[%s],error=[%s]\n----- STDOUT ----\n%s\n---- STDERR ----\n%s\n---- END ----", 
            $result->exit_code(), $result->error(), $result->stdout(), $result->stderr());
    }

    &{$options{validator}}($to_dir) if ($options{validator});
}

test_overlay('overlay', 'dev.foo.overlay', 
    validator => sub {
        my ($to_dir) = @_;
        my $to_bin_dir = File::Spec->catdir($to_dir, 'bin');
        my $to_conf_dir = File::Spec->catdir($to_dir, 'conf');

        match('catalina.sh', $to_bin_dir, $expected_bin_dir);
        match('setenv.sh', $to_bin_dir, $expected_bin_dir);
        match('jndi-resources.xml', $to_conf_dir, $expected_conf_dir);
        match('server.xml', $to_conf_dir, $expected_conf_dir);
    });

test_overlay('overlay', 'dev.foo.overlay', 
    command_args => ['--initialize'], 
    validator => sub {
        my ($to_dir) = @_;
        my $to_bin_dir = File::Spec->catdir($to_dir, 'bin');
        my $to_conf_dir = File::Spec->catdir($to_dir, 'conf');

        match('catalina.sh', $to_bin_dir, $expected_bin_dir);
        match('setenv.sh', $to_bin_dir, $expected_bin_dir);
        match('jndi-resources.xml', $to_conf_dir, $expected_conf_dir);
        match('server.xml', $to_conf_dir, $expected_conf_dir);
        match('catalina.properties', $to_conf_dir, $base_conf_dir);
    });
