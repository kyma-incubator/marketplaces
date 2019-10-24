#!/bin/bash

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

function createServiceAccount(){
    log "Create Service Acoount"
    kubectl create sa "${SERVICE_ACCOUNT}" --namespace "${NAMESPACE}"
	kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --serviceaccount="${NAMESPACE}:${SERVICE_ACCOUNT}"
}

function finalize() {
    log "Delete kind cluster"
    kind delete cluster
}

trap finalize EXIT