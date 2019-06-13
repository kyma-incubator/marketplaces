IMAGE_NAME ?= kyma-initializer
DOCKER_PUSH_REPOSITORY ?= gcr.io/kyma-project
DOCKER_TAG ?= latest
DOCKER_TAG_MINOR = $(shell echo "$(DOCKER_TAG)" | grep -o  '[0-9]\+\.[0-9]\+')
IMAGE = $(DOCKER_PUSH_REPOSITORY)$(DOCKER_PUSH_DIRECTORY)/$(IMAGE_NAME):$(DOCKER_TAG)
IMAGE_GCP = $(DOCKER_PUSH_REPOSITORY)$(DOCKER_PUSH_DIRECTORY)/kyma-gcp-marketplace:$(DOCKER_TAG) # It is required by GCP Marketplace, when changed update google-cloud/Makefile
IMAGE_GCP_MINOR = $(DOCKER_PUSH_REPOSITORY)$(DOCKER_PUSH_DIRECTORY)/kyma-gcp-marketplace:$(DOCKER_TAG_MINOR) # It is required by GCP Marketplace, when changed update google-cloud/Makefile

KYMA_VERSION = $(shell cat ../KYMA_VERSION)

.PHONY: ci-pr ci-master ci-release image-build image-push

image-build:
	docker build --build-arg KYMA_VERSION=$(KYMA_VERSION) --build-arg INITIALIZER_VERSION=$(DOCKER_TAG) -t $(IMAGE) .
	docker tag $(IMAGE) $(IMAGE_GCP)

image-push: image-build
	docker push $(IMAGE)
	docker push $(IMAGE_GCP)
ifneq (,$(shell echo "$(DOCKER_TAG)" | grep '[0-9]\+\.[0-9]\+\.[0-9]\+$$'))
	docker tag $(IMAGE_GCP) $(IMAGE_GCP_MINOR)
	docker push $(IMAGE_GCP_MINOR)
endif

ci-master: image-push
ci-pr: ci-master
ci-release: ci-master