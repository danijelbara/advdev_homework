#!/bin/bash
# Setup Production Project (initial active services: Green)
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=$1
echo "Setting up parks Production Environment in project ${GUID}-parks-prod"

# Set up Production Project
oc policy add-role-to-group system:image-puller system:serviceaccounts:${GUID}-parks-prod -n ${GUID}-parks-dev
oc policy add-role-to-user edit system:serviceaccount:${GUID}-jenkins:jenkins -n ${GUID}-parks-prod

# Create Blue Application
oc new-app ${GUID}-parks-dev/parks:0.0 --name=parks-blue --allow-missing-imagestream-tags=true -n ${GUID}-parks-prod
oc set triggers dc/parks-blue --remove-all -n ${GUID}-parks-prod
oc expose dc parks-blue --port 8080 -n ${GUID}-parks-prod
oc create configmap parks-blue-config --from-literal="application-users.properties=Placeholder" --from-literal="application-roles.properties=Placeholder" -n ${GUID}-parks-prod
oc set volume dc/parks-blue --add --name=jboss-config --mount-path=/opt/eap/standalone/configuration/application-users.properties --sub-path=application-users.properties --configmap-name=parks-blue-config -n ${GUID}-parks-prod
oc set volume dc/parks-blue --add --name=jboss-config1 --mount-path=/opt/eap/standalone/configuration/application-roles.properties --sub-path=application-roles.properties --configmap-name=parks-blue-config -n ${GUID}-parks-prod
oc set probe dc/parks-blue --readiness --get-url=http://:8080/ --initial-delay-seconds=30 --timeout-seconds=1 -n ${GUID}-parks-prod
oc set probe dc/parks-blue --liveness --get-url=http://:8080/ --initial-delay-seconds=30 --timeout-seconds=1 -n ${GUID}-parks-prod
# Setting 'wrong' VERSION. This will need to be updated in the pipeline
oc set env dc/parks-blue VERSION='0.0 (tsks-blue)' -n ${GUID}-parks-prod


# Create Green Application
oc new-app ${GUID}-parks-dev/parks:0.0 --name=parks-green --allow-missing-imagestream-tags=true -n ${GUID}-parks-prod
oc set triggers dc/parks-green --remove-all -n ${GUID}-parks-prod
oc expose dc parks-green --port 8080 -n ${GUID}-parks-prod
oc create configmap parks-green-config --from-literal="application-users.properties=Placeholder" --from-literal="application-roles.properties=Placeholder" -n ${GUID}-parks-prod
oc set volume dc/parks-green --add --name=jboss-config --mount-path=/opt/eap/standalone/configuration/application-users.properties --sub-path=application-users.properties --configmap-name=parks-green-config -n ${GUID}-parks-prod
oc set volume dc/parks-green --add --name=jboss-config1 --mount-path=/opt/eap/standalone/configuration/application-roles.properties --sub-path=application-roles.properties --configmap-name=parks-green-config -n ${GUID}-parks-prod
oc set probe dc/parks-green --readiness --get-url=http://:8080/ --initial-delay-seconds=30 --timeout-seconds=1 -n ${GUID}-parks-prod
oc set probe dc/parks-green --liveness --get-url=http://:8080/ --initial-delay-seconds=30 --timeout-seconds=1 -n ${GUID}-parks-prod
# Setting 'wrong' VERSION. This will need to be updated in the pipeline
oc set env dc/parks-green VERSION='0.0 (tsks-green)' -n ${GUID}-parks-prod

# Expose Blue service as route to make green application active
oc expose svc/parks-green --name parks -n ${GUID}-parks-prod
