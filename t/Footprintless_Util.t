use strict;
use warnings;

eval {
    require Log::Any::Adapter;
    Log::Any::Adapter->set('Stdout', log_level => 'error');
};

use Test::More tests => 4;

BEGIN {use_ok('Footprintless::Util')}


use File::Spec;
use File::Temp;

my $temp_dir = File::Temp->newdir();

my $spurt_file = File::Spec->catpath($temp_dir, 'spurt');
Footprintless::Util::spurt('foo', $spurt_file);
is(do { local( @ARGV, $/ ) = $spurt_file; <> },
    'foo', 'spurt');

my $slurp_file = File::Spec->catpath($temp_dir, 'slurp');
open(my $handle, '>', $slurp_file) || croak("cant open $slurp_file");
print($handle 'bar');
close($handle);
is(Footprintless::Util::slurp($slurp_file),
    'bar', 'slurp');

like(Footprintless::Util::dumper({foo=>'bar'}),
    qr/^\s*\$VAR1\s+=\s+\{\s+'foo'\s+=>\s+'bar'\s+\};\s*$/s,
    'dumper');
