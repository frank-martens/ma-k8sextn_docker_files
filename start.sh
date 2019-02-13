#!/bin/bash

MACHINE_AGENT_HOME=/opt/appdynamics

if [[ $ENABLE_DEBUG = "true" ]];
then
  sed -i 's/<level value="info"\/>/<level value="debug"\/>/' ${MACHINE_AGENT_HOME}/conf/logging/log4j.xml
fi

if [ -f /tmp/k8sconfig/k8sextension-config.yml ]
then
    cp -f /tmp/k8sconfig/k8sextension-config.yml ${MACHINE_AGENT_HOME}/monitors/KubernetesSnapshotExtension/config.yml
fi

MA_PROPERTIES="-Dappdynamics.controller.hostName=${CONTROLLER_HOST}"
MA_PROPERTIES+=" -Dappdynamics.controller.port=${CONTROLLER_PORT}"
MA_PROPERTIES+=" -Dappdynamics.agent.accountName=${ACCOUNT_NAME}"
MA_PROPERTIES+=" -Dappdynamics.agent.accountAccessKey=${ACCOUNT_ACCESS_KEY}"
MA_PROPERTIES+=" -Dappdynamics.controller.ssl.enabled=${CONTROLLER_SSL_ENABLED}"
MA_PROPERTIES+=" -Dappdynamics.agent.applicationName=${APPLICATION_NAME}"
MA_PROPERTIES+=" -Dappdynamics.agent.tierName=${TIER_NAME}"
MA_PROPERTIES+=" -Dappdynamics.agent.nodeName=${APPLICATION_NAME}_k8sclstrnode"
MA_PROPERTIES+=" -Dappdynamics.machine.agent.hierarchyPath=SVM-${HOSTNAME}"
MA_PROPERTIES+=" -Dappdynamics.sim.enabled=${SIM_ENABLED} -Dappdynamics.docker.enabled=false"


#MA_PROPERTIES+=" -Dappdynamics.docker.container.containerIdAsHostId.enabled=${ENABLE_CONTAINERIDASHOSTID}"

if [ "x$UNIQUE_HOSTID" != "x" ]; then
    MA_PROPERTIES+=" -Dappdynamics.agent.uniqueHostId=${UNIQUE_HOSTID}"
fi

if [ "x$PROXY_HOST" != "x" ]; then
    MA_PROPERTIES+=" -Dappdynamics.http.proxyHost=${PROXY_HOST}"
fi

if [ "x$PROXY_PORT" != "x" ]; then
    MA_PROPERTIES+=" -Dappdynamics.http.proxyPort=${PROXY_PORT}"
fi

if [ "x$PROXY_USER" != "x" ]; then
    MA_PROPERTIES+=" -Dappdynamics.http.proxyUser=${PROXY_USER}"
fi

if [ "x$PROXY_PASS" != "x" ]; then
    MA_PROPERTIES+=" -Dappdynamics.http.proxyPasswordFile=${PROXY_PASS}"
fi



if [ "x$METRIC_LIMIT" != "x" ]; then
    MA_PROPERTIES+=" -Dappdynamics.agent.maxMetrics=${METRIC_LIMIT}"
fi

# Start Machine Agent
java ${MA_PROPERTIES} -jar ${MACHINE_AGENT_HOME}/machineagent.jar
