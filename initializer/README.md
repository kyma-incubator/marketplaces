# Kyma Initializer

## Overview

Kyma Initializer is responsible for initializing Kyma installation inside Kubernetes cluster.

## Prerequisites

Use the following tools to set up the project:

* [Docker](https://www.docker.com/)

## Usage

### Build a production version

To build the production Docker image, run this command:

```bash
IMAGE={image_name}:{image_tag} DOCKER_TAG={image_tag} make image-build
```

The variables are:

* `{image_name}` which is the name of the output image. Use `kyma-initializer` for the image name.
* `{image_tag}` which is the tag of the output image. Use `latest` for the tag name.