#!/bin/bash
# Setup Development Project
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=$1
echo "Setting up parks Development Environment in project ${GUID}-parks-dev"

# Set up Dev Project
oc policy add-role-to-user edit system:serviceaccount:${GUID}-jenkins:jenkins -n ${GUID}-parks-dev

# Set up Dev Application
# oc new-build --binary=true --name="parks" jboss-eap71-openshift:1.3 -n ${GUID}-parks-dev
oc new-build --binary=true --name="parks" --image-stream=openshift/jboss-eap71-openshift:1.1 -n ${GUID}-parks-dev
oc new-app ${GUID}-parks-dev/parks:0.0-0 --name=parks --allow-missing-imagestream-tags=true -n ${GUID}-parks-dev
oc set triggers dc/parks --remove-all -n ${GUID}-parks-dev
oc expose dc parks --port 8080 -n ${GUID}-parks-dev
oc expose svc parks -n ${GUID}-parks-dev
oc create configmap parks-config --from-literal="application-users.properties=Placeholder" --from-literal="application-roles.properties=Placeholder" -n ${GUID}-parks-dev
oc set volume dc/parks --add --name=jboss-config --mount-path=/opt/eap/standalone/configuration/application-users.properties --sub-path=application-users.properties --configmap-name=parks-config -n ${GUID}-parks-dev
oc set volume dc/parks --add --name=jboss-config1 --mount-path=/opt/eap/standalone/configuration/application-roles.properties --sub-path=application-roles.properties --configmap-name=parks-config -n ${GUID}-parks-dev
oc set probe dc/parks --readiness --get-url=http://:8080/ --initial-delay-seconds=30 --timeout-seconds=1 -n ${GUID}-parks-dev
oc set probe dc/parks --liveness --get-url=http://:8080/ --initial-delay-seconds=30 --timeout-seconds=1 -n ${GUID}-parks-dev

# Setting 'wrong' VERSION. This will need to be updated in the pipeline
oc set env dc/parks VERSION='0.0 (tsks-dev)' -n ${GUID}-parks-dev
