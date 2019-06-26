#!/bin/bash
set -e
set -u

updateStatus() {
    local PHASE=${1}
    local MESSAGE=${2}

    echo 
    echo "${PHASE}: ${MESSAGE}"

    kubectl patch "applications.app.k8s.io/${APPLICATION_NAME}" \
        --namespace="${NAMESPACE}" \
        --type=merge \
        --patch="{\"spec\":{\"assemblyPhase\":\"${PHASE}\",
            \"info\":[
            {\"name\":\"Address\",\"type\":\"Reference\",\"valueFrom\":{\"type\":\"ConfigMapKeyRef\",\"configMapKeyRef\":{\"name\":\"${APPLICATION_NAME}\",\"key\":\"address\"}}},
            {\"name\":\"Email\",\"type\":\"Reference\",\"valueFrom\":{\"type\":\"ConfigMapKeyRef\",\"configMapKeyRef\":{\"name\":\"${APPLICATION_NAME}\",\"key\":\"email\"}}},
            {\"name\":\"Certificate\",\"type\":\"Reference\",\"valueFrom\":{\"type\":\"SecretKeyRef\",\"secretKeyRef\":{\"name\":\"${APPLICATION_NAME}\",\"key\":\"certificate\"}}},
            {\"name\":\"Password\",\"type\":\"Reference\",\"valueFrom\":{\"type\":\"SecretKeyRef\",\"secretKeyRef\":{\"name\":\"${APPLICATION_NAME}\",\"key\":\"password\"}}},
            {\"name\":\"Installation\",\"value\":\"${MESSAGE}\"}
            ]}}"
}

errorHandler() {
    updateStatus "Failed" "Installation failed, please check pod logs"
}

trap errorHandler ERR

updateAccessInfo() {
    local DOMAIN=${1}
    local CERTIFICATE=${2}
    local PASSWORD=${3}
    local EMAIL=${4}

    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: ${APPLICATION_NAME}
  namespace: ${NAMESPACE}
  labels:
    app.kubernetes.io/name: ${APPLICATION_NAME}
type: Opaque
data:
  password: "${PASSWORD}"
  certificate: "${CERTIFICATE}"
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: ${APPLICATION_NAME}
  namespace: ${NAMESPACE}
  labels:
    app.kubernetes.io/name: ${APPLICATION_NAME}
data:
  address: "https://${DOMAIN}"
  email: "${EMAIL}"
EOF
}

validateEnvironment() {
    local discoverUnsetVar=false

    for var in APPLICATION_NAME NAMESPACE TILLER_RESOURCE KYMA_INSTALLER_RESOURCE; do
        if [ -z "${!var}" ] ; then
            echo "ERROR: $var is not set"
            discoverUnsetVar=true
        fi
    done

    if [ "${discoverUnsetVar}" = true ] ; then
        exit 1
    fi
}

main() {
    validateEnvironment

    updateStatus "Pending" "Installing tiller"
    kubectl apply -f "${TILLER_RESOURCE}"

    updateStatus "Pending" "Installing Kyma installator"
    kubectl apply -f "${KYMA_INSTALLER_RESOURCE}"

    updateStatus "Pending" "Starting Kyma instalation"

    STATUS=Start

    while [ "$STATUS" != "Installed" ]
    do
        sleep 5
        STATUS=$(kubectl get installation/kyma-installation -o jsonpath='{.status.state}')
        DESC=$(kubectl get installation/kyma-installation -o jsonpath='{.status.description}')
    
        updateStatus "Pending" "Status ${STATUS}: ${DESC}"
    done
    
    local DOMAIN CERT PASSWORD EMAIL
    DOMAIN=$(kubectl get virtualservice core-console -n kyma-system -o jsonpath='{.spec.hosts[0]}')
    CERT=$(kubectl get configmap  net-global-overrides -n kyma-installer -o jsonpath='{.data.global\.ingress\.tlsCrt}')
    PASSWORD=$(kubectl get secret admin-user -n kyma-system -o jsonpath="{.data.password}")
    EMAIL=$(kubectl get secret admin-user -n kyma-system -o jsonpath="{.data.email}" | base64 -d)

    updateAccessInfo "${DOMAIN}" "${CERT}" "${PASSWORD}" "${EMAIL}"
    updateStatus "Succeeded" "Installed. Thank you for using Kyma."
}

main