#!/bin/bash
set -e
if [ -z "$(kubectl -n kyma-installer get job -l app=kyma-initializer,version!=1-10)" ]; then
    echo "---> Applying Tiller for ${KYMA_VERSION}"
    kubectl apply -f "https://raw.githubusercontent.com/kyma-project/kyma/${KYMA_VERSION}/installation/resources/tiller.yaml"
else
    echo "---> Skipping Tiller installation as there is a Kyma installation already"
fi