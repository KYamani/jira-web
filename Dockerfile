FROM steigr/tomcat:latest

ENV  servicedesk=servicedesk \
		 JIRA_SERVICEDESK_VERSION=3.3.1

RUN  addgroup -S servicedesk \
 &&  adduser -h /app -G servicedesk -g '' -S -D -H servicedesk \
 &&  apk add --no-cache --virtual .build-deps tar curl \
 &&  install -D -d -o servicedesk -g servicedesk /app \
 &&  curl -L https://www.atlassian.com/software/jira/downloads/binary/atlassian-servicedesk-3.3.1.tar.gz \
     | su-exec servicedesk tar -x -z -C /app --strip-components=1 \
 &&  tomcat-install /app servicedesk \
 &&  rm -rf /app/lib/hsqldb-*.jar \
            /app/lib/postgresql-*.jar \
            /app/README* \
            /app/NOTICE* \
            /app/licenses \
            /app/tomcat-docs \
 &&  xml c14n --without-comments /app/conf/server.xml | xml fo -s 2 > /app/conf/server.xml.tmp \
 &&  mv /app/conf/server.xml.tmp /app/conf/server.xml \
 &&  curl -Lo /app/lib/hsqldb-2.3.4.jar http://central.maven.org/maven2/org/hsqldb/hsqldb/2.3.4/hsqldb-2.3.4.jar \
 &&  curl -Lo /app/lib/postgresql-42.0.0.jar https://jdbc.postgresql.org/download/postgresql-42.0.0.jar \
 &&  apk del .build-deps \
 &&  rm -rf /var/cache/apk/*

RUN  export MIDANAUTHENTICATOR_VERSION=1.1.0 \
 &&  apk add --no-cache --virtual .build-deps curl \
 &&  curl -L https://github.com/MIDAN-SOFTWARE/MIDANAuthenticator/releases/download/${MIDANAUTHENTICATOR_VERSION}/midan-authenticator-${MIDANAUTHENTICATOR_VERSION:0:3}.jar \
     | install -D -o servicedesk -g servicedesk -m 0644 /dev/stdin /app/atlassian-jira/WEB-INF/lib/midan-authenticator-${MIDANAUTHENTICATOR_VERSION:0:3}.jar \
 &&  apk del .build-deps \
 &&  rm -rf /var/cache/apk/*

HEALTHCHECK CMD nc -z 127.0.0.1 8080

VOLUME /app/.oracle_jre_usage /app/work /app/logs /tmp
ENTRYPOINT ["servicedesk"]
ADD docker-entrypoint.sh /bin/servicedesk

ADD scripts/main /main
ADD scripts/vars /vars
ADD scripts/crowd-sso-configurator        /crowd-sso-configurator
ADD scripts/jira-servicedesk-configurator /jira-servicedesk-configurator

