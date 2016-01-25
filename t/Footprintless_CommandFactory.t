use strict;
use warnings;

eval {
    require Log::Log4perl;
    Log::Log4perl->easy_init($Log::Log4perl::ERROR);
    $Log::Log4perl::ERROR if (0); # prevent used only once warning
};

use Test::More tests => 3;

BEGIN {use_ok('Footprintless::CommandFactory')}

use Config::Entities;
use Footprintless::CommandFactory;

my $factory = Footprintless::CommandFactory->new(
    Config::Entities->new({
        entity => {
            dev => {
                hostname => 'web.local',
                logs => {
                    access_log => '/var/log/httpd/access_log',
                    catalina => {
                        file => '/opt/apache/tomcat/logs/catalina.out',
                        hostname => 'localhost',
                        sudo_username => undef,
                    }
                },
                ssh => 'ssh -q',
                sudo_username => 'apache',
            }
        }
    }));

is($factory->tail_command('dev.logs.access_log'), 
    'ssh -q web.local "sudo -u apache tail -f /var/log/httpd/access_log"', 
    'tail access_log');
is($factory->tail_command('dev.logs.catalina'), 
    'tail -f /opt/apache/tomcat/logs/catalina.out', 
    'tail catalina');
