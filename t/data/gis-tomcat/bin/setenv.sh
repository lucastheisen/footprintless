JAVA_HOME="/usr/lib/jvm/java"
JPDA_PORT=8586
JMX_PORT=8587

CAS_JAVA_OPTS="\
    -Dfile.encoding=UTF8 \
    -Djava.awt.headless=true \
    -Duser.timezone=GMT \
    -Dorg.apache.catalina.loader.WebappClassLoader.ENABLE_CLEAR_REFERENCES=false \
    -Djava.net.preferIPv4Stack=true"

MEMORY_JAVA_OPTS="\
    -Xms256m \
    -Xmx512m \
    "
SERVLET_OPTS="\
    -Dorg.apache.el.parser.COERCE_TO_ZERO=false \
    "
SSL_JAVA_OPTS="\
    -Djavax.net.ssl.trustStoreType=JKS \
    -Djavax.net.ssl.trustStorePassword=set4now \
    -Djavax.net.ssl.trustStore=\"C:/Users/ltheisen/git/asias-piab/gis-tomcat/../ssl/trustStore.jks\" \
    "
JMX_OPTS="\
    -Dcom.sun.management.jmxremote \
    -Dcom.sun.management.jmxremote.port=$JMX_PORT \
    -Dcom.sun.management.jmxremote.ssl=false \
    -Dcom.sun.management.jmxremote.authenticate=false \
    "
JPDA_OPTS="\
    -Xdebug \
    -Xrunjdwp:transport=dt_socket,address=$JPDA_PORT,server=y,suspend=n \
    "

CATALINA_OPTS=$JMX_OPTS
CATALINA_PID=/var/run/gis-tomcat/catalina.pid
JAVA_OPTS="$JAVA_OPTS $MEMORY_JAVA_OPTS $CAS_JAVA_OPTS $SSL_JAVA_OPTS $SERVLET_OPTS"

export JAVA_HOME CATALINA_OPTS JAVA_OPTS CATALINA_PID
