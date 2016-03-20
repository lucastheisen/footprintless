use strict;
use warnings;

use lib 't/lib';

use Config::Entities;
use File::Basename;
use File::Path qw(make_path);
use File::Spec;
use Footprintless::Localhost;
use Footprintless::Util qw(
    default_command_runner 
    dumper 
    slurp 
    spurt
);
use Footprintless::Test::Util qw(
    is_empty_dir
);
use Test::More tests => 22;

BEGIN {use_ok('Footprintless::Deployment')}

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

sub entities {
    my ($name, $to_dir, %resources) = @_;

    return Config::Entities->new({
        entity => {
            $name => {
                deployment => {
                    configuration => {
                        to_dir => $to_dir,
                        clean => ["$to_dir/"]
                    },
                    hostname => 'localhost',
                    resources => \%resources
                }
            }
        }
    });
}

sub temp_dirs {
    File::Temp::cleanup();

    my $temp_dir = File::Temp->newdir();
    my $to_dir = File::Spec->catdir($temp_dir, 'to');
    make_path($to_dir);

    return $temp_dir, $to_dir;
}

{
    my ($temp_dir, $to_dir) = temp_dirs();

    my $barwar = File::Spec->catfile($test_dir, 'data', 'resources', 'bar.war');
    my $to_barwar = File::Spec->catfile($to_dir, 'bar.war');
    my $bazwar = File::Spec->catfile($test_dir, 'data', 'resources', 'baz.war');
    my $to_bazwar = File::Spec->catfile($to_dir, 'baz.war');

    my $deployment = Footprintless::Deployment->new(
        entities('foo', $to_dir, bar => $barwar, baz => $bazwar),
        'foo.deployment');
    $deployment->deploy();

    ok(-f $to_barwar, 'bar deployed');
    is(slurp($to_barwar), slurp($barwar), 'bar is bar');
    ok(-f $to_bazwar, 'baz deployed');
    is(slurp($to_bazwar), slurp($bazwar), 'baz is baz');

    $deployment->clean();
    ok(-d $to_dir, 'to is dir');
    ok(is_empty_dir($to_dir), 'to is clean');
}

SKIP: {
    my $command_runner = default_command_runner();
    eval {
        $command_runner->run_or_die('ssh localhost echo hello', 
            {timeout => 2});
    };
    if ($@) {
        skip("cannot ssh to localhost: $@", 6);
    }

    my ($temp_dir, $to_dir) = temp_dirs();

    my $barwar = File::Spec->catfile($test_dir, 'data', 'resources', 'bar.war');
    my $to_barwar = File::Spec->catfile($to_dir, 'bar.war');
    my $bazwar = File::Spec->catfile($test_dir, 'data', 'resources', 'baz.war');
    my $to_bazwar = File::Spec->catfile($to_dir, 'baz.war');

    my $deployment = Footprintless::Deployment->new(
        entities('foo', $to_dir, bar => $barwar, baz => $bazwar),
        'foo.deployment',
        localhost => Footprintless::Localhost->new(none => 1));
    $deployment->deploy();

    ok(-f $to_barwar, 'remote bar deployed');
    is(slurp($to_barwar), slurp($barwar), 'remote bar is bar');
    ok(-f $to_bazwar, 'remote baz deployed');
    is(slurp($to_bazwar), slurp($bazwar), 'remote baz is baz');

    $deployment->clean();
    ok(-d $to_dir, 'remote to is dir');
    ok(is_empty_dir($to_dir), 'remote to is clean');
}

{
    my ($temp_dir, $to_dir) = temp_dirs();
    my $to_local_dir = File::Temp->newdir();

    my $barwar = File::Spec->catfile($test_dir, 'data', 'resources', 'bar.war');
    my $to_barwar = File::Spec->catfile($to_local_dir, 'bar.war');
    my $bazwar = File::Spec->catfile($test_dir, 'data', 'resources', 'baz.war');
    my $to_bazwar = File::Spec->catfile($to_local_dir, 'baz.war');

    my $deployment = Footprintless::Deployment->new(
        entities('foo', $to_dir, bar => $barwar, baz => $bazwar),
        'foo.deployment');
    $deployment->deploy(rebase => {'from' => $to_dir, to => $to_local_dir});
    ok(is_empty_dir($to_dir), 'to_local_dir to is clean');

    ok(-f $to_barwar, 'bar deployed');
    is(slurp($to_barwar), slurp($barwar), 'to_local_dir bar is bar');
    ok(-f $to_bazwar, 'baz deployed');
    is(slurp($to_bazwar), slurp($bazwar), 'to_local_dir baz is baz');
}

{
    my ($temp_dir, $to_dir) = temp_dirs();

    my $barwar = File::Spec->catfile($test_dir, 'data', 'resources', 'bar.war');
    my $to_foobarwar = File::Spec->catfile($to_dir, 'foobar.war');
    my $bazwar = File::Spec->catfile($test_dir, 'data', 'resources', 'baz.war');
    my $to_foobazwar = File::Spec->catfile($to_dir, 'foobaz.war');

    my $deployment = Footprintless::Deployment->new(
        entities('foo', $to_dir, 
            bar => {
                url => $barwar,
                'as' => 'foobar.war'
            }, 
            baz => {
                url => $bazwar,
                'as' => 'foobaz.war'
            }),
        'foo.deployment');
    $deployment->deploy();

    ok(-f $to_foobarwar, 'foobar deployed');
    is(slurp($to_foobarwar), slurp($barwar), 'foobar is bar');
    ok(-f $to_foobazwar, 'foobaz deployed');
    is(slurp($to_foobazwar), slurp($bazwar), 'foobaz is baz');
}
