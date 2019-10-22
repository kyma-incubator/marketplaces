#!/bin/bash


SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CLUSTER_DIR="$( cd "${SCRIPT_DIR}/../cluster" && pwd )"
ARTIFACTS_PATH="${ARTIFACTS:-"${SCRIPT_DIR}/out"}"
INSTALLATIONTIMEOUT=108000 #in this case it mean 30 minutes
CR_NAMESPACE="${NAMESPACE:-"default"}"
SERVICE_ACCOUNT="kyma-serviceaccount"

function log() {
    echo "$(date +"%Y/%m/%d %T %Z"): ${1}"
}

function installDefaultResources() {
    log "Make kubernetes.io/host-path Storage Class as non default"
    kubectl annotate storageclass standard storageclass.kubernetes.io/is-default-class="false" storageclass.beta.kubernetes.io/is-default-class="false" --overwrite

    log "Install default resources from ${CLUSTER_DIR}/resources/"
    kubectl apply -f "${CLUSTER_DIR}/resources/"
}

function startDocker() {
    log "Docker in Docker enabled, initializing..."
    printf '=%.0s' {1..80}; echo
    # If we have opted in to docker in docker, start the docker daemon,
    service docker start
    # the service can be started but the docker socket not ready, wait for ready
    local WAIT_N=0
    local MAX_WAIT=20
    while true; do
        # docker ps -q should only work if the daemon is ready
        docker ps -q > /dev/null 2>&1 && break
        if [[ ${WAIT_N} -lt ${MAX_WAIT} ]]; then
            WAIT_N=$((WAIT_N+1))
            log "Waiting for docker to be ready, sleeping for ${WAIT_N} seconds."
            sleep ${WAIT_N}
        else
            log "Reached maximum attempts, not waiting any longer..."
            exit 1
        fi
    done
    printf '=%.0s' {1..80}; echo

    docker-credential-gcr configure-docker
    log "Done setting up docker in docker."
}

function createCluster() {
    log "Create kind cluster"
    kind create cluster --config "${CLUSTER_DIR}/cluster.yaml" --wait 3m
    readonly KUBECONFIG="$(kind get kubeconfig-path --name="kind")"
    cp "${KUBECONFIG}" "${HOME}/.kube/config"
    kubectl cluster-info
}

function finalize() {
    log "Delete kind cluster"
    kind delete cluster
}

function kymaState(){
    return "$(kubectl -n default get installation/kyma-installation -o jsonpath="{.status.state}")"
}

function kymaInstallationState(){
    return "$(kubectl -n default get installation/kyma-installation -o jsonpath="Status: {.status.state}, Description: {.status.description}")"
}

function monitorInstallation(){
    log "Waiting for Kyma..."

    TIMETOWAIT=2
    TIMECOUNTER=0
    COMPONENT=""

    while [ "$(kymaState)" != "Installed" ] ;
    do
        NEWCOMPONENT=$(kymaInstallationState)

        if [ "${NEWCOMPONENT}" != "${COMPONENT}" ]
        then
            log  "$(date +"%T") ${NEWCOMPONENT}";
            if [ "${TIMECOUNTER}" -gt "${INSTALLATIONTIMEOUT}" ]
            then
                log "Installation timeout"
                exit 1
            fi
            COMPONENT=${NEWCOMPONENT}
        fi

        sleep ${TIMETOWAIT};
        TIMECOUNTER=$(( TIMECOUNTER + TIMETOWAIT ))
    done

    log "Kyma status: Installed"
}

function createServiceAccount(){
    kubectl create sa "${SERVICE_ACCOUNT}" --namespace "${CR_NAMESPACE}"
	kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --serviceaccount="${CR_NAMESPACE}:${SERVICE_ACCOUNT}"
}

function applyArtifacts(){
    kubectl apply -f "https://raw.githubusercontent.com/GoogleCloudPlatform/marketplace-k8s-app-tools/master/crd/app-crd.yaml"
    kubectl apply -f "${ARTIFACTS_PATH}/*"
}

trap finalize EXIT

if docker info > /dev/null 2>&1 ; then
    log "startDocker"
    startDocker
fi

log "createCluster"
createCluster

log "installDefaultResources"
installDefaultResources

log "create serviceclass ${SERVICE_ACCOUNT}"
createServiceAccount

log "apply ${ARTIFACTS_PATH}"
applyArtifacts

log "monitor installation"
sleep 10
monitorInstallation
