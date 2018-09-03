FROM docker-registry.sec.cloudwatt.com/ubuntu/18.04

ARG application_version

RUN apt-get update && apt-get install -y --no-install-recommends \
    bzip2 vim-tiny unzip xz-utils openjdk-8-jre-headless \
    libtcnative-1 xmlstarlet

RUN apt clean

# Default to UTF-8 file.encoding
ENV LANG C.UTF-8

# add a simple script that can auto-detect the appropriate JAVA_HOME value
# based on whether the JDK or only the JRE is installed
RUN { \
    echo '#!/bin/sh'; \
    echo 'set -e'; \
    echo; \
    echo 'dirname "$(dirname "$(readlink -f "$(which javac || which java)")")"'; \
  } > /usr/local/bin/docker-java-home \
  && chmod +x /usr/local/bin/docker-java-home

ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64/jre


RUN set -x \
  && [ "$JAVA_HOME" = "$(docker-java-home)" ]

# Configuration variables.
ENV JIRA_HOME     /var/atlassian/jira
ENV JIRA_INSTALL  /opt/atlassian/jira
ENV JIRA_SOFTWARE_VERSION  7.11.2
ENV JIRA_SERVICEDESK_VERSION  3.14.2
ENV MYSQL_JCONNECTOR 5.1.38

# Install Atlassian JIRA and helper tools and setup initial home
# directory structure.
RUN set -x \
    && mkdir -p                "${JIRA_HOME}" \
    && mkdir -p                "${JIRA_HOME}/caches/indexes" \
    && chmod -R 700            "${JIRA_HOME}" \
    && chown -R daemon:daemon  "${JIRA_HOME}" \
    && mkdir -p                "${JIRA_INSTALL}/conf/Catalina"

## Installatation de Jira SOFTWARE
RUN curl -Ls "https://nexus.sec.cloudwatt.com/nexus/content/sites/external/jira/atlassian-jira-software-${JIRA_SOFTWARE_VERSION}.tar.gz" | tar -xvz --directory "${JIRA_INSTALL}" --strip-components=1 --no-same-owner

## Installatation de Jira ServiceDesk
RUN curl -Ls "https://nexus.sec.cloudwatt.com/nexus/content/sites/external/jira/atlassian-servicedesk-${JIRA_SERVICEDESK_VERSION}.tar.gz" | tar -xvz --directory "${JIRA_INSTALL}" --strip-components=1 --no-same-owner

# Installation de Mysql 8.0.11
# RUN curl -Ls "https://nexus.sec.cloudwatt.com/nexus/content/sites/external/mysql/mysql-connector-java-${MYSQL_JCONNECTOR}.tar.gz" | tar -xvz --directory "${JIRA_INSTALL}/lib" --strip-components=1 --no-same-owner "mysql-connector-java-${MYSQL_JCONNECTOR}/mysql-connector-java-${MYSQL_JCONNECTOR}.jar"

# Installation de Mysql 5.1.38
RUN curl -Ls "https://nexus.sec.cloudwatt.com/nexus/content/sites/external/mysql/mysql-connector-java-${MYSQL_JCONNECTOR}.jar" -o ${JIRA_INSTALL}/lib/mysql-connector-java-${MYSQL_JCONNECTOR}.jar

RUN chmod -R 700            "${JIRA_INSTALL}/conf" \
    && chmod -R 700            "${JIRA_INSTALL}/logs" \
    && chmod -R 700            "${JIRA_INSTALL}/temp" \
    && chmod -R 700            "${JIRA_INSTALL}/work" \
    && chown -R daemon:daemon  "${JIRA_INSTALL}/conf" \
    && chown -R daemon:daemon  "${JIRA_INSTALL}/logs" \
    && chown -R daemon:daemon  "${JIRA_INSTALL}/temp" \
    && chown -R daemon:daemon  "${JIRA_INSTALL}/work"

RUN chown     daemon:daemon  "${JIRA_INSTALL}/bin" \
    && chown  daemon:daemon  "${JIRA_INSTALL}/bin/setenv.sh"

RUN echo -e                 "\njira.home=$JIRA_HOME" >> "${JIRA_INSTALL}/atlassian-jira/WEB-INF/classes/jira-application.properties" \
    && touch -d "@0"           "${JIRA_INSTALL}/conf/server.xml" \
    && echo '#!/bin/sh' > /opt/atlassian/jira/bin/check-java.sh


RUN sed -i '/JVM_MINIMUM_MEMORY="384m"/D' "${JIRA_INSTALL}/bin/setenv.sh"
RUN sed -i '/JVM_MAXIMUM_MEMORY="768m"/D' "${JIRA_INSTALL}/bin/setenv.sh"
RUN echo "" > /etc/java-8-openjdk/accessibility.properties

# Use the default unprivileged account. This could be considered bad practice
# on systems where multiple processes end up being executed by 'daemon' but
# here we only ever run one process anyway.
USER daemon:daemon

# Expose default HTTP connector port.
EXPOSE 8080

# Set volume mount points for installation and home directory. Changes to the
# home directory needs to be persisted as well as parts of the installation
# directory due to eg. logs.
VOLUME ["/var/atlassian/jira", "/opt/atlassian/jira/logs"]

# Set the default working directory as the installation directory.
WORKDIR /var/atlassian/jira

COPY "docker-entrypoint.sh" "/"
ENTRYPOINT ["/docker-entrypoint.sh"]

# Run Atlassian JIRA as a foreground process by default.
CMD ["/opt/atlassian/jira/bin/catalina.sh", "run"]
