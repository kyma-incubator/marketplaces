#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR="$( cd "${SCRIPT_DIR}/../cluster" && pwd )"
SERVICE_ACCOUNT="${SERVICE_ACCOUNT:-"kyma-serviceaccount"}"
ARTIFACTS="${ARTIFACTS:-"${ROOT_DIR}/in"}"
NAMESPACE="${NAMESPACE:-"default"}"
INSTALLATIONTIMEOUT=1800 #in this case it mean 30 minutes

# shellcheck disable=SC1090
source "${SCRIPT_DIR}/common.sh"

function createCluster() {
    kind create cluster --config "${ROOT_DIR}/cluster.yaml" --wait 3m
    readonly KUBECONFIG="$(kind get kubeconfig-path --name="kind")"
    cp "${KUBECONFIG}" "${HOME}/.kube/config"
    kubectl cluster-info
}

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

log "createCluster"
createCluster

log "installDefaultResources"
installDefaultResources

log "create serviceclass ${SERVICE_ACCOUNT}"
createServiceAccount

log "apply artifacts"
applyArtifacts

log "Waiting for Kyma..."
monitorInstallation

exit 0