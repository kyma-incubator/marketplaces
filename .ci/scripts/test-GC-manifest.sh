#!/usr/bin/env bash
set -e

readonly ARGS=("$@")
readonly SCRIPTS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
readonly CI_DIR="$( cd "${SCRIPTS_DIR}/.." && pwd )"
readonly KUBERNETES_VERSION="${KUBERNETES_VERSION:-"v1.15.3"}"
readonly ARTIFACTS="${ARTIFACTS:-"${CI_DIR}/in"}"
readonly INSTALLATIONTIMEOUT=1800 #in this case it mean 30 minutes

# shellcheck disable=SC1090
source "${SCRIPTS_DIR}/common.sh"

ENSUREKUBECTL="false"

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
                echo " "
                echo "Environment variables:"
                echo "  KUBERNETES_VERSION   Version of kubernetes for kind installation"
                exit 0
                ;;
            --ensure-kubectl)
                shift
                ENSUREKUBECTL="true"
                ;;
            *)
                log "$1 is not a recognized flag, use --help flag for a list of avaiable options!"
                return 1
                ;;
        esac
    done

    readonly ENSUREKUBECTL
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
            log "Last pods state:"
            getAllPods
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

function getLastInstallationState(){
    log "All pods:"
    kubectl get pods --all-namespaces

    log "Initializer logs:"
    kubectl logs -l app.kubernetes.io/name=kyma --tail=1000
}

readFlags "${ARGS[@]}"

if [ "${ENSUREKUBECTL}" == "true" ]
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