# Kyma Add-On for Gardener

## Overview

This project provides a helm chart to be used as Addon for [Gardener](https://gardener.cloud)

The chart installs a set of Kubernetes Jobs installing and starting the Kyma Installer.

## Prerequisites

Use the following tools to set up the project:

* [Helm](https://helm.sh)

## Usage

To install the Kyma Add-On manually on a Gardener cluster, follow these steps:

1. Render the Helm chart:

    ```bash
    helm template . > output.yaml
    ```

2. Apply Kubernetes resources:

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

If you want to execute the job manually, see the [manual installation](manual-install.md) instructions.
