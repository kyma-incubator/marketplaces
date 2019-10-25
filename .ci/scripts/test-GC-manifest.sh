#!/usr/bin/env bash
set -eox

readonly SCRIPTS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
readonly CI_DIR="$( cd "${SCRIPTS_DIR}/.." && pwd )"
readonly KUBERNETES_VERSION="$( cat "${CI_DIR}/KIND_KUBERNETES_VERSION" )"
readonly ARTIFACTS="${ARTIFACTS:-"${CI_DIR}/in"}"
readonly INSTALLATIONTIMEOUT=1800 #in this case it mean 30 minutes

# shellcheck disable=SC1090
source "${SCRIPTS_DIR}/common.sh"

INSTALLKUBECTL="true"

function getAssemblyPhase(){
    kubectl get Application.app.k8s.io kyma -o jsonpath="{.spec.assemblyPhase}"
}

function monitorInstallation(){
    TIMETOWAIT=2
    TIMECOUNTER=0
    PHASE=""
    NEWPHASE=""

    while [ "${NEWPHASE}" != "Succeeded" ] ;
    do
        NEWPHASE=$(getAssemblyPhase)

        if [ "${TIMECOUNTER}" -gt "${INSTALLATIONTIMEOUT}" ]
        then
            log "Installation timeout"
            exit 1
        fi

        if [ "${PHASE}" != "${NEWPHASE}" ]
        then
            PHASE="${NEWPHASE}"
            log "${PHASE}"
        fi

        sleep ${TIMETOWAIT};
        TIMECOUNTER=$(( TIMECOUNTER + TIMETOWAIT ))
    done

    log "Kyma status: ${PHASE}"
}

function applyArtifacts(){
    kubectl apply -f "https://raw.githubusercontent.com/GoogleCloudPlatform/marketplace-k8s-app-tools/master/crd/app-crd.yaml"
    kubectl apply -f "${ARTIFACTS}"
}

if [ "${INSTALLKUBECTL}" == "true" ]
then
    log "Install kubectl in version ${KUBERNETES_VERSION}"
    ensureExpectedKubectlVersion
fi

log "createCluster"
createCluster

log "installDefaultResources"
installDefaultResources

log "create serviceclass"
createServiceAccount

log "apply artifacts"
applyArtifacts

log "Waiting for Kyma..."
monitorInstallation

exit 0