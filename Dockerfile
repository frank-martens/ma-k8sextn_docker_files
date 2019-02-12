# pull the latest 4.5 machine agent
FROM store/appdynamics/machine:4.5

ENV MACHINE_AGENT_HOME /opt/appdynamics

RUN mkdir $MACHINE_AGENT_HOME/monitors/KubernetesSnapshotExtension/
COPY ./KubernetesSnapshotExtension/ $MACHINE_AGENT_HOME/monitors/KubernetesSnapshotExtension/

COPY ./k8s_dashboard_eks-production_template.json $MACHINE_AGENT_HOME/monitors/KubernetesSnapshotExtension/templates/k8s_dashboard_template.json

COPY ./start.sh $MACHINE_AGENT_HOME
RUN chmod +x $MACHINE_AGENT_HOME/start.sh
CMD “start.sh” 
