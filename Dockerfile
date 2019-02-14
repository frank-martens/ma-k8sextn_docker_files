# pull the latest 4.5 machine agent
FROM openjdk:8-jdk-alpine

RUN apk add --no-cache bash curl gawk sed grep bc coreutils

ENV MACHINE_AGENT_HOME /opt/appdynamics

COPY ./MachineAgent/ $MACHINE_AGENT_HOME

COPY ./k8s_dashboard_eks-production_template.json $MACHINE_AGENT_HOME/monitors/KubernetesSnapshotExtension/templates/k8s_dashboard_template.json

COPY ./start.sh $MACHINE_AGENT_HOME
RUN chmod +x $MACHINE_AGENT_HOME/start.sh

CMD "$MACHINE_AGENT_HOME/start.sh"
