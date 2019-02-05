#!/bin/bash
# Create Homework Projects with GUID prefix.
# When FROM_JENKINS=true then project ownership is set to USER
# Set FROM_JENKINS=false for testing outside of the Grading Jenkins
if [ "$#" -ne 3 ]; then
    echo "Usage:"
    echo "  $0 GUID USER FROM_JENKINS"
    exit 1
fi

GUID=$1
USER=$2
FROM_JENKINS=$3

echo "Creating Homework Projects for GUID=${GUID} and USER=${USER}"
oc new-project ${GUID}-jenkins    --display-name="${GUID} AdvDev Homework Jenkins"
oc new-project ${GUID}-parks-dev  --display-name="${GUID} AdvDev Homework Tasks Development"
oc new-project ${GUID}-parks-prod --display-name="${GUID} AdvDev Homework parks Production"

if [ "$FROM_JENKINS" = "true" ]; then
  oc policy add-role-to-user admin ${USER} -n ${GUID}-jenkins
  oc policy add-role-to-user admin ${USER} -n ${GUID}-parks-dev
  oc policy add-role-to-user admin ${USER} -n ${GUID}-parks-prod

  oc annotate namespace ${GUID}-jenkins    openshift.io/requester=${USER} --overwrite
  oc annotate namespace ${GUID}-parks-dev  openshift.io/requester=${USER} --overwrite
  oc annotate namespace ${GUID}-parks-prod openshift.io/requester=${USER} --overwrite
fi
