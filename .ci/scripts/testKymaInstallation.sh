#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR="$( cd "${SCRIPT_DIR}/../cluster" && pwd )"
SERVICE_ACCOUNT="${SERVICE_ACCOUNT:-"kyma-serviceaccount"}"
ARTIFACTS="${ARTIFACTS:-"${SCRIPT_DIR}/out"}"
NAMESPACE="${NAMESPACE:-"default"}"
INSTALLATIONTIMEOUT=1800 #in this case it mean 30 minutes

function log() {
    echo "$(date +"%Y/%m/%d %T %Z"): ${1}"
}

function installDefaultResources() {
    log "Make kubernetes.io/host-path Storage Class as non default"
    kubectl annotate storageclass standard storageclass.kubernetes.io/is-default-class="false" storageclass.beta.kubernetes.io/is-default-class="false" --overwrite

    log "Create kyma-installer namespace"
    kubectl create namespace kyma-installer

    log "Install default resources from ${ROOT_DIR}/resources/"
    kubectl apply -f "${ROOT_DIR}/resources/"
}

function createCluster() {
    kind create cluster --config "${ROOT_DIR}/cluster.yaml" --wait 3m
    readonly KUBECONFIG="$(kind get kubeconfig-path --name="kind")"
    cp "${KUBECONFIG}" "${HOME}/.kube/config"
    kubectl cluster-info
}

function finalize() {
    log "Delete kind cluster"
    kind delete cluster
}

function getAssemblyPhase(){
    kubectl get Application kyma -o jsonpath="{.spec.assemblyPhase}"
}

function monitorInstallation(){
    TIMETOWAIT=2
    TIMECOUNTER=0
    PHASE=""
    NEWPHASE=""

    while [ "${NEWPHASE}" != "Installed" ] ;
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

function createServiceAccount(){
    kubectl create sa "${SERVICE_ACCOUNT}" --namespace "${NAMESPACE}"
	kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --serviceaccount="${NAMESPACE}:${SERVICE_ACCOUNT}"
}

function applyArtifacts(){
    kubectl apply -f "https://raw.githubusercontent.com/GoogleCloudPlatform/marketplace-k8s-app-tools/master/crd/app-crd.yaml"
    kubectl apply -f "${ARTIFACTS}"
}

trap finalize EXIT

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