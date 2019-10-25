#!/usr/bin/env bash
set -eox

readonly NAMESPACE="${NAMESPACE:-"default"}"
readonly SERVICE_ACCOUNT="${SERVICE_ACCOUNT:-"kyma-serviceaccount"}"
readonly KIND_IMAGE="${KIND_IMAGE:-"kindest/node:${KUBERNETES_VERSION}"}"
readonly CLUSTER_DIR="${CI_DIR}/cluster"

function log() {
    echo "$(date +"%Y/%m/%d %T %Z"): ${1}"
}

function createCluster() {
    kind create cluster --config "${CLUSTER_DIR}/cluster.yaml" --wait 3m --image "${KIND_IMAGE}"
    readonly KUBECONFIG="$(kind get kubeconfig-path --name="kind")"
    cp "${KUBECONFIG}" "${HOME}/.kube/config"
    kubectl cluster-info
}

function installDefaultResources() {
    log "Make kubernetes.io/host-path Storage Class as non default"
    kubectl annotate storageclass standard storageclass.kubernetes.io/is-default-class="false" storageclass.beta.kubernetes.io/is-default-class="false" --overwrite

    log "Create kyma-installer namespace"
    kubectl create namespace kyma-installer

    log "Install default resources from ${CLUSTER_DIR}/resources"
    kubectl apply -f "${CLUSTER_DIR}/resources"
}

function createServiceAccount(){
    log "Create Service Acoount"
    kubectl create sa "${SERVICE_ACCOUNT}" --namespace "${NAMESPACE}"
	kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --serviceaccount="${NAMESPACE}:${SERVICE_ACCOUNT}"
}

function ensureExpectedKubectlVersion() {
    if command -v kubectl >/dev/null 2>&1; then
        log "Removing built-in kubectl version"
        rm -rf "$(command -v kubectl)"
    fi

    curl -LO "https://storage.googleapis.com/kubernetes-release/release/${KUBERNETES_VERSION}/bin/linux/amd64/kubectl" --fail \
        && chmod +x kubectl \
        && mv kubectl /usr/local/bin/kubectl
}

function finalize() {
    log "Delete kind cluster"
    kind delete cluster
}

trap finalize EXIT