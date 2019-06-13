IMAGE_NAME ?= kyma-initializer
DOCKER_PUSH_REPOSITORY ?= gcr.io/kyma-project
DOCKER_TAG ?= latest
IMAGE = $(DOCKER_PUSH_REPOSITORY)$(DOCKER_PUSH_DIRECTORY)/$(IMAGE_NAME):$(DOCKER_TAG)
IMAGE_GCP = $(DOCKER_PUSH_REPOSITORY)$(DOCKER_PUSH_DIRECTORY)/kyma-gcp-marketplace/$(IMAGE_NAME):$(DOCKER_TAG) # It is required by GCP Marketplace, when changed update google-cloud/Makefile

KYMA_VERSION = $(shell cat ../KYMA_VERSION)

.PHONY: ci-pr ci-master ci-release image-build image-push

image-build:
	docker build --build-arg KYMA_VERSION=$(KYMA_VERSION) --build-arg INITIALIZER_VERSION=$(DOCKER_TAG) -t $(IMAGE) .
	docker tag $(IMAGE) $(IMAGE_GCP)

image-push: image-build
	docker push $(IMAGE)
	docker push $(IMAGE_GCP)

ci-master: image-push
ci-pr: ci-master
ci-release: ci-master