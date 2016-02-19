use strict;
use warnings;

use File::Basename;
use File::Spec;
use File::Temp;
use Footprintless::Util qw(slurp);
use Footprintless::Resource::UrlProvider;
use LWP::UserAgent;
use Test::More tests => 8;

BEGIN {use_ok('Footprintless::ResourceManager')}

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

my $lwp = LWP::UserAgent->new();
$lwp->env_proxy();

my $path = File::Spec->catfile($test_dir, 'config', 'properties.pl');
my $url = "file://$path";

my $url_provider = Footprintless::Resource::UrlProvider->new($lwp);
my $manager = Footprintless::ResourceManager->new($url_provider);
is($manager->resource($url)->get_url(), $url, 'UrlProvider resolve');
is(slurp($manager->download($url)), slurp($path), 'UrlProvider download');

my $http_url = "http://www.google.com/foo";
is($manager->resource($http_url)->get_url(), $http_url, 'UrlProvider resolve http');

SKIP: {
    skip('Maven::Agent not installed', 3) unless (require Maven::Agent);
    my $coordinate = 'javax.servlet:servlet-api:2.5';
    my ($agent, $expected_artifact);
    eval {
        $agent = Maven::Agent->new();
        $expected_artifact = $agent->resolve_or_die($coordinate);
    };
    skip('maven environment not setup', 3) if ($@);
    
    require Footprintless::Resource::MavenProvider;
    my $manager = Footprintless::ResourceManager->new(
        Footprintless::Resource::MavenProvider->new($agent));
    is($manager->resource($coordinate)->get_artifact(),
        $expected_artifact,
        'MavenProvider resolve');

    $manager = Footprintless::ResourceManager->new(
        Footprintless::Resource::MavenProvider->new($agent),
        $url_provider);
    is($manager->resource($coordinate)->get_artifact(), $expected_artifact,
        'both MavenProvider resolve');
    is($manager->resource($path)->get_url(), $url,
        'both UrlProvider resolve path');
    is($manager->resource($url)->get_url(), $url,
        'both UrlProvider resolve url');
}
