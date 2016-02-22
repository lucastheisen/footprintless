use strict;
use warnings;

use lib 't/lib';

use File::Basename;
use File::Spec;
use File::Temp;
use Footprintless::Test::Util qw(maven_agent);
use Footprintless::Resource::UrlProvider;
use Footprintless::Util qw(slurp);
use LWP::UserAgent;
use Test::More tests => 10;

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
    my $test_count = 4;
    my $coordinate = 'com.pastdev:foo:pom:1.0.1';

    my $temp_dir = File::Temp->newdir();
    my $agent;
    eval {
        $agent = maven_agent($temp_dir);
    };
    skip($@, $test_count) if ($@);

    my $expected_artifact;
    eval {
        $expected_artifact = $agent->resolve_or_die($coordinate);
    };
    skip('maven environment not setup', $test_count) if ($@);
    
    require Footprintless::Resource::MavenProvider;
    my $manager = Footprintless::ResourceManager->new(
        Footprintless::Resource::MavenProvider->new($agent));
    is($manager->resource($coordinate)->get_artifact(),
        $expected_artifact,
        'MavenProvider resolve');
    my $local_repo_artifact_path = File::Spec->catfile($temp_dir, 'HOME', '.m2', 'repository', 
            'com', 'pastdev', 'foo', '1.0.1', 'foo-1.0.1.pom');
    my $download_path = $manager->download($coordinate);
    is($download_path, $local_repo_artifact_path, 'file found in local repo');
    is(slurp($download_path), slurp($local_repo_artifact_path), 'artifact download matches');

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
