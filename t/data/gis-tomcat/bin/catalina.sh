#!/bin/sh

CATALINA_HOME="/opt/apache/tomcat"
CATALINA_BASE="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"

export CATALINA_BASE CATALINA_HOME

$CATALINA_HOME/bin/catalina.sh "$@"
