use strict;
use warnings;

use App::Cmd::Tester;
use Data::Dumper;
use Footprintless;
use File::Basename;
use File::Spec;
use Test::More tests => 3;

BEGIN {use_ok('Footprintless::App')}

my $test_dir = dirname( File::Spec->rel2abs( $0 ) );

$ENV{FPL_CONFIG_DIRS} = File::Spec->catdir($test_dir, 'config', 'entities');
$ENV{FPL_CONFIG_PROPS} = File::Spec->catfile($test_dir, 'config', 'credentials.pl');

is(test_app('Footprintless::App' => 
    [
        'config',
        'dev.piab.os',
        '--format', 
        'dumper0' 
    ])->stdout(), 
    "\$VAR1 = 'linux';", 'dev.piab.os = linux');
is(test_app('Footprintless::App' => 
    [
        'config', 
        'dev.piab', 
        '--format', 
        'json2' 
    ])->stdout(), 
   '{"catalina_home":"/opt/apache-tomcat/apache-tomcat","java_home":"/usr/lib/jvm/java","os":"linux","tomcat_artifact":"org.apache.tomcat:tomcat:zip:7.0.52"}',
   'json dev.piab = {...}');
