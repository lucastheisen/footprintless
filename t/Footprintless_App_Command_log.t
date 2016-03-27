use strict;
use warnings;

use lib 't/lib';

use App::Cmd::Tester;
use Data::Dumper;
use Footprintless;
use Footprintless::Util qw(slurp spurt);
use File::Basename;
use File::Path qw(make_path);
use File::Spec;
use File::Temp;
use Test::More tests => 1;#5;

BEGIN {use_ok('Footprintless::App')}
if (0) {

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

sub footprintless {
    my ($temp_dir) = @_;

    my $entities_dir = File::Spec->catdir($temp_dir, 'config', 'entities');
    make_path($entities_dir);
    my $foo = File::Spec->catfile($entities_dir, 'foo.pm');
    spurt(<<"    FOO", $foo);
    return {
        logs => {
            bar => '$temp_dir/bar.log',
            baz => '$temp_dir/baz.log'
        }
    }
    FOO

    # Get the current entities
    $ENV{FPL_CONFIG_DIRS} = File::Spec->catdir($entities_dir);
    delete($ENV{FPL_CONFIG_PROPS});

    return Footprintless->new();
}

my $temp_dir = File::Temp->newdir();

my $footprintless = footprintless($temp_dir);
my $bar_coordinate = 'foo.logs.bar';
my $bar_log = $footprintless->entities()->get_entity($bar_coordinate);
is($bar_log, "$temp_dir/bar.log", 'bar log');
my $baz_coordinate = 'foo.logs.baz';
my $baz_log = $footprintless->entities()->get_entity($baz_coordinate);
is($baz_log, "$temp_dir/baz.log", 'baz log');

if ($logger->is_trace) {
    $logger->tracef('entities %s', 
        Data::Dumper->new([$footprintless->entities()])->Indent(1)->Dump());
}

spurt("one\ntwo\nthree\nfour\nfive", $bar_log);
spurt("nine\neight\nseven\nsix\nfive", $baz_log);

my $result = test_app('Footprintless::App' => ['log', $bar_coordinate, 'cat']);
print("REMOVE ME: ", Dumper($result), "\n");
if (1) {
is(test_app('Footprintless::App' => ['log', $bar_coordinate, 'cat'])->stdout(),
    "one\ntwo\nthree\nfour\nfive",
    'cat bar');
is(test_app('Footprintless::App' => ['log', $baz_coordinate, 'cat'])->stdout(),
    "nine\neight\nseven\nsix\nfive",
    'cat baz');
}
}
