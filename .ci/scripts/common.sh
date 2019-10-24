#!/usr/bin/env bash
set -eox

NAMESPACE="${NAMESPACE:-"default"}"
SERVICE_ACCOUNT="${SERVICE_ACCOUNT:-"kyma-serviceaccount"}"
CLUSTER_DIR="${CI_DIR}/cluster"

function log() {
    echo "$(date +"%Y/%m/%d %T %Z"): ${1}"
}

function createCluster() {
    kind create cluster --config "${CLUSTER_DIR}/cluster.yaml" --wait 3m
    readonly KUBECONFIG="$(kind get kubeconfig-path --name="kind")"
    cp "${KUBECONFIG}" "${HOME}/.kube/config"
    kubectl cluster-info
}

function installDefaultResources() {
    log "Make kubernetes.io/host-path Storage Class as non default"
    kubectl annotate storageclass standard storageclass.kubernetes.io/is-default-class="false" storageclass.beta.kubernetes.io/is-default-class="false" --overwrite

    log "Create kyma-installer namespace"
    kubectl create namespace kyma-installer

    log "Install default resources from ${CLUSTER_DIR}/resources/"
    kubectl apply -f "${CLUSTER_DIR}/resources/"
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