#!/usr/bin/env bash
set -eo pipefail

readonly SCRIPTS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
readonly CI_DIR="$( cd "${SCRIPTS_DIR}/.." && pwd )"
readonly LIB_DIR="$( cd "${GOPATH}/src/github.com/kyma-project/test-infra/prow/scripts/lib" && pwd )"
readonly CLUSTER_DIR="$( cd "${CI_DIR}/cluster" && pwd )"
readonly RESOURCES_DIR="$( cd "${CLUSTER_DIR}/resources" && pwd )"
readonly CLUSTER_CONFIG="${CLUSTER_DIR}/cluster.yaml"
readonly KUBERNETES_VERSION="${KUBERNETES_VERSION:-"v1.15.3"}"
readonly ARTIFACTS_DIR="${ARTIFACTS:-"${CI_DIR}/in"}"
readonly INSTALLATIONTIMEOUT=1000 #in this case it mean 20 minutes
readonly CLUSTER_NAME="${CLUSTER_NAME:-"kyma"}"
readonly NAMESPACE="${NAMESPACE:-"default"}"
readonly SERVICE_ACCOUNT="${SERVICE_ACCOUNT:-"kyma-serviceaccount"}"

# shellcheck disable=SC1090
source "${LIB_DIR}/log.sh"
# shellcheck disable=SC1090
source "${LIB_DIR}/junit.sh"
# shellcheck disable=SC1090
source "${LIB_DIR}/docker.sh"
# shellcheck disable=SC1090
source "${LIB_DIR}/kind.sh"
# shellcheck disable=SC1090
source "${LIB_DIR}/kubernetes.sh"

ENSUREKUBECTL="false"
START_DOCKER="false"
TUNE_INOTIFY="false"
DOMAIN=kyma.local

function readFlags() {
    while test $# -gt 0; do
        case "$1" in
            -h|--help)
                shift
                echo "Script that tests manifest for google-cloud marketplace"
                echo " "
                echo "Options:"
                echo "  -h --help            Print usage."
                echo "     --ensure-kubectl  Update kubectl to the same version as cluster."
                echo "     --start-docker    Start the Docker Daemon."
                echo "     --tune-inotify    Tune inotify instances and watches."
                echo " "
                echo "Environment variables:"
                echo "  ARTIFACTS  If not set, all artifacts are stored in \`.ci/in\` directory"
                exit 0
                ;;
            --ensure-kubectl)
                shift
                ENSUREKUBECTL="true"
                ;;
            --start-docker)
                shift
                START_DOCKER="true"
                ;;
            --tune-inotify)
                shift
                TUNE_INOTIFY="true"
                ;;
            *)
                log::info "$1 is not a recognized flag, use --help flag for a list of avaiable options!"
                return 1
                ;;
        esac
    done

    readonly ENSUREKUBECTL START_DOCKER TUNE_INOTIFY
}

function monitorInstallation() {
    TIMETOWAIT=2
    TIMECOUNTER=0
    STATE=""
    PHASE=""
    while [ "${PHASE}" != "Succeeded" ] ;
    do
        PHASE=$(getAssemblyPhase)

        if [ "${TIMECOUNTER}" -gt "${INSTALLATIONTIMEOUT}" ]
        then
            log::info "Installation timeout"
            log::info "Last pods state:"
            getLastInstallationState
            exit 1
        fi

        if [ "${PHASE}" == "Pending" ]
        then
            NEWSTATE="$(getInstallationState)"
            if [ "${STATE}" != "${NEWSTATE}" ]
            then
                STATE="${NEWSTATE}"
                log::info "${STATE}"
            fi 
        fi

        sleep ${TIMETOWAIT};
        TIMECOUNTER=$(( TIMECOUNTER + TIMETOWAIT ))
    done

    log::info "Kyma status: ${STATE}"
}

function getAssemblyPhase(){
    kubectl get Application.app.k8s.io kyma -o jsonpath="{.spec.assemblyPhase}"
}

function getInstallationState(){
    kubectl get Application.app.k8s.io kyma -o jsonpath="{.spec.info[4].value}"
}

function applyArtifacts(){
    kubectl apply -f "https://raw.githubusercontent.com/GoogleCloudPlatform/marketplace-k8s-app-tools/master/crd/app-crd.yaml"
    kubectl apply -f "${ARTIFACTS_DIR}"
}

function getLastInstallationState(){
    log::info "All pods:"
    kubectl get pods --all-namespaces

    log::info "Initializer:"
    kubectl logs -l app.kubernetes.io/name=kyma --tail=1000
}

function createServiceAccount() {
    log::info "Create Service Acoount"
    kubectl create sa "${SERVICE_ACCOUNT}" --namespace "${NAMESPACE}"
	kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --serviceaccount="${NAMESPACE}:${SERVICE_ACCOUNT}"
}

function createNamespace() {
    log::info "Create $1 namespace"
    kubectl create namespace "$1"
}

function tune_inotify() {
    log::info "Increasing limits for inotify"
    sysctl -w fs.inotify.max_user_watches=524288
    sysctl -w fs.inotify.max_user_instances=512
}

function finalize() {
    local -r exit_status=$?
    local finalization_failed="false"

    junit::test_start "Finalization"
    log::info "Finalizing job" 2>&1 | junit::test_output

    log::info "Printing all docker processes" 2>&1 | junit::test_output
    docker::print_processes 2>&1 | junit::test_output || finalization_failed="true"

    if [[ ${CLUSTER_PROVISIONED} = "true" ]]; then
        log::info "Exporting cluster logs to ${ARTIFACTS_DIR}" 2>&1 | junit::test_output
        kind::export_logs "${CLUSTER_NAME}" 2>&1 | junit::test_output || finalization_failed="true"

        log::info "Deleting cluster" 2>&1 | junit::test_output
        kind::delete_cluster "${CLUSTER_NAME}" 2>&1 | junit::test_output || finalization_failed="true"
    fi

    if [[ ${finalization_failed} = "true" ]]; then
        junit::test_fail || true
    else
        junit::test_pass
    fi

    junit::suite_save

    return "${exit_status}"
}

function customize_resources(){
    CLUSTER_IP=$(kind::worker_ip "${CLUSTER_NAME}")

    log::info "Customize 03-overrides.yaml"        
    value=$(< "${RESOURCES_DIR}/03-overrides.yaml" sed 's/\.minikubeIP: .*/\.minikubeIP: '\""${CLUSTER_IP}"\"'/g' \
       | sed 's/\.domainName: .*/\.domainName: '\""${DOMAIN}"\"'/g')
    echo "$value" > "${RESOURCES_DIR}/03-overrides.yaml"
}

function main(){
    trap junit::test_fail ERR
    junit::suite_init "Kyma_Integration"

    junit::test_start "Tune_Inotify"
    if [[ ${TUNE_INOTIFY} = "true" ]]; then
        tune_inotify 2>&1 | junit::test_output
        junit::test_pass
    else
        junit::test_skip "Disabled"
    fi

    junit::test_start "Start_Docker_Daemon"
    if [[ ${START_DOCKER} = "true" ]]; then
        log::info "Starting Docker daemon" 2>&1 | junit::test_output
        docker::start 2>&1 | junit::test_output
        junit::test_pass
    else
        junit::test_skip "Disabled"
    fi

    junit::test_start "Ensure_Kubectl"
    if [ "${ENSUREKUBECTL}" == "true" ]
    then
        log::info "Ensure_Kubectl" 2>&1 | junit::test_output
        kubernetes::ensure_kubectl "${KUBERNETES_VERSION}" 2>&1 | junit::test_output
        junit::test_pass
    else
        junit::test_skip
    fi

    junit::test_start "Create_Cluster"
    log::info "Create_Cluster" 2>&1 | junit::test_output
    kind::create_cluster "${CLUSTER_NAME}" "${KUBERNETES_VERSION}" "${CLUSTER_CONFIG}" 2>&1 | junit::test_output
    CLUSTER_PROVISIONED="true"
    readonly CLUSTER_PROVISIONED
    junit::test_pass

    junit::test_start "Install_Default_Resources"
    log::info "Install_Default_Resources" 2>&1 | junit::test_output
    createNamespace "kyma-installer" 2>&1 | junit::test_output
    customize_resources 2>&1 | junit::test_output
    kind::install_default "${RESOURCES_DIR}" 2>&1 | junit::test_output
    junit::test_pass

    junit::test_start "Create_Serviceclass"
    log::info "Create_Serviceclass" 2>&1 | junit::test_output
    createServiceAccount 2>&1 | junit::test_output
    junit::test_pass

    junit::test_start "Apply_Artifacts"
    log::info "Apply_Artifacts" 2>&1 | junit::test_output
    applyArtifacts 2>&1 | junit::test_output
    junit::test_pass

    junit::test_start "Waiting_For_Kyma..."
    log::info "Waiting_For_Kyma..." 2>&1 | junit::test_output
    monitorInstallation 2>&1 | junit::test_output
    junit::test_pass
}

trap finalize EXIT

readFlags "${@}"
main
