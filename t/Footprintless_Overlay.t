use strict;
use warnings;

use Config::Entities;
use File::Basename;
use File::Path qw(make_path);
use File::Spec;
use Footprintless::CommandOptionsFactory;
use Footprintless::Localhost;
use Footprintless::Util qw(
    default_command_runner 
    dumper 
    slurp 
    spurt
);
use Test::More tests => 15;

BEGIN {use_ok('Footprintless::Overlay')}

eval {
    require Getopt::Long;
    Getopt::Long::Configure('pass_through', 'bundling');
    my $level = 'error';
    Getopt::Long::GetOptions(
        'log:s' => \$level
    );

    require Log::Any::Adapter;
    Log::Any::Adapter->set('Stdout', 
        log_level => Log::Any::Adapter::Util::numeric_level($level));
};

my $logger = Log::Any->get_logger();

my $test_dir = dirname(File::Spec->rel2abs($0));

sub temp_dirs {
    File::Temp::cleanup();

    my $temp_dir = File::Temp->newdir();
    my $base_dir = File::Spec->catdir($temp_dir, 'base');
    my $to_dir = File::Spec->catdir($temp_dir, 'to');
    my $template_dir = File::Spec->catdir($temp_dir, 'template');
    make_path($base_dir, $to_dir, $template_dir);

    return $temp_dir, $base_dir, $to_dir, $template_dir;
}

{
    $logger->info('Verify initialize');
    my ($temp_dir, $base_dir, $to_dir, $template_dir) = temp_dirs();
    my $hostname = 'localhost';
    my $overlay = Footprintless::Overlay->new(
        Config::Entities->new({
            entity => {
                system => {
                    hostname => $hostname,
                    app => {
                        'Config::Entities::inherit' => ['hostname'],
                        overlay => {
                            'Config::Entities::inherit' => ['hostname', 'sudo_username'],
                            base_dir => $base_dir,
                            clean => ["$to_dir/"],
                            key => 'T',
                            os => $^O,
                            resolver_coordinate => 'system',
                            template_dir => $template_dir,
                            to_dir => $to_dir
                        }
                    }
                }
            }
        }),
        'system.app.overlay');
    ok($overlay, 'overlay constructed');

    my $name = 'foo';
    my $template_file = File::Spec->catfile($template_dir, $name);
    my $to_file = File::Spec->catfile($to_dir, $name);
    spurt('hostname=[${T{app.hostname}}]', $template_file);
    my $base_template_file = File::Spec->catfile($base_dir, $name);
    spurt('i should be overlayed', $base_template_file);
    my $base_name = 'bar';
    my $base_file = File::Spec->catfile($base_dir, $base_name);
    spurt('bar', $base_file);
    $overlay->initialize();
    is(slurp($to_file), "hostname=[$hostname]", 'initialize template');
    is(slurp($base_file), "bar", 'initialize base');
}

{
    $logger->info('Verify update');
    my ($temp_dir, $base_dir, $to_dir, $template_dir) = temp_dirs();
    my $hostname = 'localhost';
    my $overlay = Footprintless::Overlay->new(
        Config::Entities->new({
            entity => {
                system => {
                    hostname => $hostname,
                    app => {
                        'Config::Entities::inherit' => ['hostname'],
                        overlay => {
                            'Config::Entities::inherit' => ['hostname', 'sudo_username'],
                            base_dir => $base_dir,
                            clean => ["$to_dir/"],
                            key => 'T',
                            os => $^O,
                            resolver_coordinate => 'system',
                            template_dir => $template_dir,
                            to_dir => $to_dir
                        }
                    }
                }
            }
        }),
        'system.app.overlay');
    ok($overlay, 'overlay constructed');

    my $name = 'foo';
    my $template_file = File::Spec->catfile($template_dir, $name);
    my $to_file = File::Spec->catfile($to_dir, $name);
    spurt('hostname=[${T{app.hostname}}]', $template_file);
    $overlay->update();
    is(slurp($to_file), "hostname=[$hostname]", 'update');
}

{
    $logger->info('Verify clean');
    my ($temp_dir, $base_dir, $to_dir, $template_dir) = temp_dirs();
    my $overlay = Footprintless::Overlay->new(
        Config::Entities->new({
            entity => {
                overlay => {
                    hostname => 'localhost',
                    base_dir => $base_dir,
                    clean => ["$to_dir/"],
                    key => 'T',
                    os => $^O,
                    resolver_coordinate => 'system',
                    template_dir => $template_dir,
                    to_dir => $to_dir
                }
            }
        }),
        'overlay');
    my $to_file = File::Spec->catfile($to_dir, 'bar');
    spurt('foo', $to_file);
    ok(-f $to_file, 'clean test to_file created');
    $overlay->clean();
    ok(!-e $to_file, 'clean test');
}

{
    $logger->info('Verify deployment on initialize');
    my ($temp_dir, $base_dir, $to_dir, $template_dir) = temp_dirs();

    my $webapps_dir = File::Spec->catdir($to_dir, 'webapps');
    my $barwar = File::Spec->catfile($test_dir, 'data', 'resources', 'bar.war');
    my $to_barwar = File::Spec->catfile($webapps_dir, 'bar.war');
    my $bazwar = File::Spec->catfile($test_dir, 'data', 'resources', 'baz.war');
    my $to_bazwar = File::Spec->catfile($webapps_dir, 'baz.war');

    my $overlay = Footprintless::Overlay->new(
        Config::Entities->new({
            entity => {
                system => {
                    deployment => {
                        configuration => {
                            clean => ["$webapps_dir/"],
                            to_dir => $webapps_dir
                        },
                        resources => {
                            bar => $barwar,
                            baz => $bazwar
                        }
                    },
                    overlay => {
                        hostname => 'localhost',
                        base_dir => $base_dir,
                        clean => ["$to_dir/"],
                        deployment_coordinate => 'system.deployment',
                        key => 'T',
                        os => $^O,
                        resolver_coordinate => 'system',
                        template_dir => $template_dir,
                        to_dir => $to_dir
                    }
                }
            }
        }),
        'system.overlay');

    $overlay->initialize();

    ok(-f $to_barwar, "bar deployed $to_barwar");
    is(slurp($to_barwar), slurp($barwar), 'bar is bar');
    ok(-f $to_bazwar, 'baz deployed');
    is(slurp($to_bazwar), slurp($bazwar), 'baz is baz');
}

SKIP: {
    $logger->info('Verify non-local');
    my $command_runner = default_command_runner();
    eval {
        $command_runner->run_or_die('ssh localhost echo hello', 
            {timeout => 2});
    };
    if ($@) {
        skip("cannot ssh to localhost: $@", 3);
    }

    my ($temp_dir, $base_dir, $to_dir, $template_dir) = temp_dirs();
    my $hostname = 'localhost';
    my $overlay = Footprintless::Overlay->new(
        Config::Entities->new({
            entity => {
                system => {
                    hostname => $hostname,
                    app => {
                        'Config::Entities::inherit' => ['hostname'],
                        overlay => {
                            'Config::Entities::inherit' => ['hostname', 'sudo_username'],
                            base_dir => $base_dir,
                            clean => ["$to_dir/"],
                            key => 'T',
                            os => $^O,
                            resolver_coordinate => 'system',
                            template_dir => $template_dir,
                            to_dir => $to_dir
                        }
                    }
                }
            }
        }),
        'system.app.overlay',
        localhost => Footprintless::Localhost->new(none => 1));
    ok($overlay, 'overlay constructed');

    my $name = 'foo';
    my $template_file = File::Spec->catfile($template_dir, $name);
    my $to_file = File::Spec->catfile($to_dir, $name);
    spurt('hostname=[${T{app.hostname}}]', $template_file);
    my $base_template_file = File::Spec->catfile($base_dir, $name);
    spurt('i should be overlayed', $base_template_file);
    my $base_name = 'bar';
    my $base_file = File::Spec->catfile($base_dir, $base_name);
    spurt('bar', $base_file);
    $overlay->initialize();
    is(slurp($to_file), "hostname=[$hostname]", 'initialize template');
    is(slurp($base_file), "bar", 'initialize base');
}
