#!/bin/bash
set -e

if [ -z "$(kubectl -n kyma-installer get job -l app=kyma-initializer,version!=${KYMA_VERSION})" ]; then
    echo "---> Applying Kyma-Installer for ${KYMA_VERSION}"
    kubectl apply -f "https://raw.githubusercontent.com/kyma-project/kyma/${KYMA_VERSION}/installation/resources/installer.yaml"

    echo "---> Apply Kyma installation CR for ${KYMA_VERSION}"
    kubectl apply -f "https://raw.githubusercontent.com/kyma-project/kyma/${KYMA_VERSION}/installation/resources/installer-cr-cluster.yaml.tpl"
else
    echo "---> Skipping Kyma installation as there is a Kyma installation already"
fi