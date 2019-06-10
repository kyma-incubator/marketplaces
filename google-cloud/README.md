# Kyma Google Cloud Marketplace

## Overview

This project provides Kyma configuration for Google Cloud Marketplace.

## Prerequisites

Use the following tools to set up the project:

* [Docker](https://www.docker.com/)
* [gcloud](https://www.docker.com/)
* [envsubst](https://www.gnu.org/software/gettext/manual/html_node/envsubst-Invocation.html)

## Usage

### Install application on cluster manually

To install application manually on Google Kubernetes Engine cluster, follow these steps:
1. Export variables
    ```bash
    export GCP_PROJECT={GCP project}
    export GCP_CLUSTER_NAME={GKE cluster name}
    export KYMA_INITIALIZER_IMAGE={Kyma Initializer image}
    ```
2. Create cluster
    ```bash
    make cluster-create
    ```
3. Install resources
    ```bash
    make install
    ```
4. Open displayed link that points to Applications view in Google Cloud Project

## Access build artifacts

 - To access build artifacts from Pull Request job, use following template:
    ```
    https://storage.googleapis.com/kyma-prow-logs/pr-logs/pull/kyma-incubator_marketplaces/{PR_NUMBER}/pre-marketplaces/{JOB_ID}/artifacts/google-cloud-manifest.yaml
    ```
- To access build artifacts from Merge job, use following template:
    ```
    https://storage.googleapis.com/kyma-prow-logs/logs/post-marketplaces/{JOB_ID}/artifacts/google-cloud-manifest.yaml
    ```
- To access build artifacts from Release job, use following template:
    ```
    https://storage.googleapis.com/kyma-prow-logs/logs/rel-marketplaces/{JOB_ID}/artifacts/google-cloud-manifest.yaml
    ```