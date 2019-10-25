IMAGE_NAME ?= deployer
DOCKER_PUSH_REPOSITORY ?= gcr.io/kyma-project
DOCKER_TAG ?= latest
DOCKER_TAG_MINOR = $(shell echo "$(DOCKER_TAG)" | grep -o  '[0-9]\+\.[0-9]\+')
IMAGE = $(DOCKER_PUSH_REPOSITORY)$(DOCKER_PUSH_DIRECTORY)/kyma-gcp-marketplace/$(IMAGE_NAME):$(DOCKER_TAG)
IMAGE_MINOR = $(DOCKER_PUSH_REPOSITORY)$(DOCKER_PUSH_DIRECTORY)/kyma-gcp-marketplace/$(IMAGE_NAME):$(DOCKER_TAG_MINOR)
ARTIFACTS ?= out
GCP_ZONE ?= europe-west3-a
NAMESPACE ?= default
APPLICATION_NAME ?= kyma
SERVICE_ACCOUNT ?= kyma-serviceaccount
ifeq (,$(shell echo "$(DOCKER_TAG)" | grep '[0-9]\+\.[0-9]\+\.[0-9]\+$$'))
KYMA_INITIALIZER_IMAGE ?= $(DOCKER_PUSH_REPOSITORY)$(DOCKER_PUSH_DIRECTORY)/kyma-gcp-marketplace:$(DOCKER_TAG)
else
KYMA_INITIALIZER_IMAGE ?= $(DOCKER_PUSH_REPOSITORY)$(DOCKER_PUSH_DIRECTORY)/kyma-gcp-marketplace:$(DOCKER_TAG_MINOR)
endif
VERSION ?= $(DOCKER_TAG)

KYMA_VERSION = $(shell cat ../KYMA_VERSION)

.EXPORT_ALL_VARIABLES:
.PHONY: ci-pr ci-master ci-release image-build image-push cluster-create cluster-attach cluster-service-account install manifest-build check-env tests-run gettext-install

cluster-create: check-env
	gcloud container --project "$(GCP_PROJECT)" clusters \
	create "$(GCP_CLUSTER_NAME)" --zone "$(GCP_ZONE)" \
	--cluster-version "1.13" --machine-type "n1-standard-4" \
	--addons HorizontalPodAutoscaling,HttpLoadBalancing

cluster-attach: check-env
	gcloud container clusters get-credentials "$(GCP_CLUSTER_NAME)" --zone="$(GCP_ZONE)" --project="$(GCP_PROJECT)"

cluster-service-account: check-env
	kubectl create sa "$(SERVICE_ACCOUNT)" --namespace "$(NAMESPACE)"
	kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --serviceaccount="$(NAMESPACE):$(SERVICE_ACCOUNT)"

install: check-env manifest-build cluster-attach cluster-service-account
	kubectl apply -f "https://raw.githubusercontent.com/GoogleCloudPlatform/marketplace-k8s-app-tools/master/crd/app-crd.yaml"
	kubectl apply -f $(ARTIFACTS)/*
	@echo "Application: https://console.cloud.google.com/kubernetes/application/$(GCP_ZONE)/$(GCP_CLUSTER_NAME)/$(NAMESPACE)/$(APPLICATION_NAME)?project=$(GCP_PROJECT)"

manifest-build:
	@echo "Generating manifest"
	@mkdir -p $(ARTIFACTS)
	@awk 'FNR==1 {print "---"}{print}' manifest/* \
	| envsubst '$$VERSION $$APPLICATION_NAME $$NAMESPACE $$SERVICE_ACCOUNT $$KYMA_INITIALIZER_IMAGE' \
	> "$(ARTIFACTS)/google-cloud-manifest.yaml"

image-build:
	docker build \
	    --build-arg KYMA_VERSION=$(KYMA_VERSION) \
		--build-arg DEPLOYER_VERSION=$(DOCKER_TAG) \
		--build-arg KYMA_INITIALIZER_IMAGE=$(KYMA_INITIALIZER_IMAGE) \
		-t $(IMAGE) .

tests-run:
	../.ci/scripts/test-GC-manifest.sh --ensure-kubectl

image-push: image-build
	docker push $(IMAGE)
ifneq (,$(shell echo "$(DOCKER_TAG)" | grep '[0-9]\+\.[0-9]\+\.[0-9]\+$$'))
	docker tag $(IMAGE) $(IMAGE_MINOR)
	docker push $(IMAGE_MINOR)
endif

gettext-install:
	@apt-get install -y --no-install-recommends gettext

ci-master: gettext-install manifest-build image-push
ci-pr: ci-master tests-run
ci-release: ci-master

check-env:
ifndef GCP_PROJECT
	$(error GCP_PROJECT is undefined)
endif
ifndef GCP_CLUSTER_NAME
	$(error GCP_CLUSTER_NAME is undefined)
endif