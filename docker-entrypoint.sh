#!/bin/bash

if [ ! -e "${JIRA_INSTALL}/conf/server.xml.org" ]; then
  cp "${JIRA_INSTALL}/conf/server.xml" "${JIRA_INSTALL}/conf/server.xml.org"
fi

cp "${JIRA_INSTALL}/conf/server.xml.org" "${JIRA_INSTALL}/conf/server.xml"

if [ -n "${X_PROXY_NAME}" ]; then
  xmlstarlet ed --inplace --insert '//Connector[@port="8080"]' --type "attr" --name "proxyName" --value "${X_PROXY_NAME}" "${JIRA_INSTALL}/conf/server.xml"
fi
if [ -n "${X_PROXY_PORT}" ]; then
  xmlstarlet ed --inplace --insert '//Connector[@port="8080"]' --type "attr" --name "proxyPort" --value "${X_PROXY_PORT}" "${JIRA_INSTALL}/conf/server.xml"
fi
if [ -n "${X_PROXY_SCHEME}" ]; then
  xmlstarlet ed --inplace --insert '//Connector[@port="8080"]' --type "attr" --name "scheme" --value "${X_PROXY_SCHEME}" "${JIRA_INSTALL}/conf/server.xml"
fi
if [ -n "${X_PATH}" ]; then
  xmlstarlet ed --inplace --update '//Context/@path' --value "${X_PATH}" "${JIRA_INSTALL}/conf/server.xml"
fi

xmlstarlet ed --inplace --insert '//Connector' --type "attr" --name "secure" --value "${X_SECURE:-true}" "${JIRA_INSTALL}/conf/server.xml"

xmlstarlet ed --inplace --update '//jdbc-datasource/url' \
  --value "jdbc:mysql://${X_DB_HOST:-mysql}:${X_DB_PORT:-3306}/${X_DB_NAME:-jiradb}?useUnicode=true&characterEncoding=UTF8&sessionVariables=default_storage_engine=InnoDB" \
  "${JIRA_HOME}/dbconfig.xml"
xmlstarlet ed --inplace --update '//jdbc-datasource/username' --value "${X_DB_USERNAME:-root}" "${JIRA_HOME}/dbconfig.xml"
xmlstarlet ed --inplace --update '//jdbc-datasource/password' --value "${X_DB_PASSWORD}" "${JIRA_HOME}/dbconfig.xml"
xmlstarlet ed --inplace --insert '//jdbc-datasource/url' --type "elem" -n pool-test-on-borrow --value "false" "${JIRA_HOME}/dbconfig.xml"

sed -i 's/JVM_SUPPORT_RECOMMENDED_ARGS="/JVM_SUPPORT_RECOMMENDED_ARGS="'"${JVM_SUPPORT_RECOMMENDED_ARGS}"' /g' "${JIRA_INSTALL}/bin/setenv.sh"

exec "$@"
