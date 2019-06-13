IMAGE_NAME ?= kyma-initializer
DOCKER_PUSH_REPOSITORY ?= gcr.io/kyma-project
DOCKER_TAG ?= latest
IMAGE = $(DOCKER_PUSH_REPOSITORY)$(DOCKER_PUSH_DIRECTORY)/$(IMAGE_NAME):$(DOCKER_TAG)

KYMA_VERSION = $(shell cat ../KYMA_VERSION)

.PHONY: ci-pr ci-master ci-release image-build image-push

image-build:
	docker build --build-arg KYMA_VERSION=$(KYMA_VERSION) --build-arg INITIALIZER_VERSION=$(DOCKER_TAG) -t $(IMAGE) .

image-push: image-build
	docker push $(IMAGE)

ci-master: image-push
ci-pr: ci-master
ci-release: ci-master