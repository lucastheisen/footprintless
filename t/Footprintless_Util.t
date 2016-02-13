use strict;
use warnings;

use File::Spec;
use File::Temp;
use Test::More tests => 4;

BEGIN {use_ok('Footprintless::Util')}

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

my $temp_dir = File::Temp->newdir();
$logger->trace('temp_dir [%s]', $temp_dir);

my $spurt_file = File::Spec->catfile($temp_dir, 'spurt');
$logger->trace('writing to [%s]', $spurt_file);
Footprintless::Util::spurt('foo', $spurt_file);
is(do { local( @ARGV, $/ ) = $spurt_file; <> },
    'foo', 'spurt');

my $slurp_file = File::Spec->catfile($temp_dir, 'slurp');
$logger->trace('writing to [%s]', $slurp_file);
open(my $handle, '>', $slurp_file) || croak("cant open $slurp_file");
print($handle 'bar');
close($handle);
is(Footprintless::Util::slurp($slurp_file),
    'bar', 'slurp');

like(Footprintless::Util::dumper({foo=>'bar'}),
    qr/^\s*\$VAR1\s+=\s+\{\s+'foo'\s+=>\s+'bar'\s+\};\s*$/s,
    'dumper');
