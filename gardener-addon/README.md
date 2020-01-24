# Kyma Gardener Addon

## Overview

This project provides a helm chart to be used as Addon for [Gardener](https://gardener.cloud)

It will install a set of Kubernetes Jobs installing and starting the Kyma-Installer.

## Prerequisites

Use the following tools to set up the project:

* [Helm](https://helm.sh)

## Usage

To install the addon manually on a Gardener cluster, follow these steps:

1. Render helm chart:

    ```bash
    helm template . > output.yaml
    ```

2. Apply the kubernetes resources:

    ```bash
    kubectl apply -f output.yaml
    ```

3. Check jobs for healthy execution:

    ```bash
    kubectl -n kyma-installer get jobs -w
    ```

4. Check installation progress:

    ```bash
    kubectl -n kyma-installer logs kyma-initializer-dns-XXX -c wait-for-installation -f
    ```

5. Check for final completion
    ```bash
    kubectl -n kyma-installer logs kyma-initializer-dns-XXX
    ```

## Details

For doing the steps of the job in a manual way, see the [manual install](manual-install.md) instructions.