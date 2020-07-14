# Kyma Google Cloud Marketplace

> **CAUTION:** As a result of [Kubernetes API deprecation](https://kubernetes.io/blog/2019/07/18/api-deprecations-in-1-16/), Kyma can no longer be installed through the GCP Marketplace. That is why, we temporary disabled Kyma on GCP Marketplace until we make changes necessary to fix the installation issues.

## Overview

This project provides Kyma configuration for the Google Cloud Marketplace.

## Prerequisites

Use the following tools to set up the project:

* [Docker](https://www.docker.com/)
* [gcloud](https://www.docker.com/)
* [envsubst](https://www.gnu.org/software/gettext/manual/html_node/envsubst-Invocation.html)

## Usage

### Install the application manually

To install the application manually on a Google Kubernetes Engine cluster, follow these steps:

1. Export variables:

    ```bash
    export GCP_PROJECT={GCP project}
    export GCP_CLUSTER_NAME={GKE cluster name}
    export KYMA_INITIALIZER_IMAGE={Kyma Initializer image}
    ```

2. Create a cluster:

    ```bash
    make cluster-create
    ```

3. Install resources:

    ```bash
    make install
    ```

4. Open the displayed link that points to the **Applications** view in the Google Cloud Project.

### Access build artifacts

* To access build artifacts from a presubmit job, use following template:

    ```text
    https://storage.googleapis.com/kyma-prow-logs/pr-logs/pull/kyma-incubator_marketplaces/{PR_NUMBER}/pre-marketplaces/{JOB_ID}/artifacts/google-cloud-manifest.yaml
    ```

* To access build artifacts from a postsubmit job, use following template:

    ```text
    https://storage.googleapis.com/kyma-prow-logs/logs/post-marketplaces/{JOB_ID}/artifacts/google-cloud-manifest.yaml
    ```

* To access build artifacts from a release job, use following template:

    ```text
    https://storage.googleapis.com/kyma-prow-logs/logs/rel-marketplaces/{JOB_ID}/artifacts/google-cloud-manifest.yaml
    ```

### Run the integration test manually

Follow the steps to run the integration pipeline for the repository.

1. Export variables:

    ```bash
    export DOCKER_TAG=$(<"KYMA_VERSION" cat | tr -d " \t\n")
    export ARTIFACTS="$GOPATH/src/github.com/kyma-incubator/marketplaces/google-cloud/out"
    ```

2. Build the manifest:

    ```bash
    make -C google-cloud/ manifest-build
    ```

3. Run the test:

    ```bash
    ./.ci/scripts/test-GC-manifest.sh
    ```
