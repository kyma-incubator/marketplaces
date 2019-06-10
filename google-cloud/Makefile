IMAGE_NAME ?= kyma-gc-deployer
DOCKER_PUSH_REPOSITORY ?= eu.gcr.io/kyma-project/marketplaces
DOCKER_TAG ?= latest
IMAGE = $(DOCKER_PUSH_REPOSITORY)$(DOCKER_PUSH_DIRECTORY)/$(IMAGE_NAME):$(DOCKER_TAG)
ARTIFACTS ?= out
GCP_ZONE ?= europe-west3-a
NAMESPACE ?= default
APPLICATION_NAME ?= kyma
SERVICE_ACCOUNT ?= kyma-serviceaccount
KYMA_INITIALIZER_IMAGE ?= $(DOCKER_PUSH_REPOSITORY)$(DOCKER_PUSH_DIRECTORY)/kyma-initializer:$(DOCKER_TAG)
VERSION ?= $(DOCKER_TAG)

KYMA_VERSION = $(shell cat ../KYMA_VERSION)

.EXPORT_ALL_VARIABLES:
.PHONY: ci-pr ci-master ci-release image-build image-push cluster-create cluster-attach cluster-service-account install manifest-build check-env

cluster-create: check-env
	gcloud container --project "$(GCP_PROJECT)" clusters \
	create "$(GCP_CLUSTER_NAME)" --zone "$(GCP_ZONE)" \
	--cluster-version "1.12" --machine-type "n1-standard-4" \
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

image-push: image-build
	docker push $(IMAGE)

ci-master: manifest-build image-push
ci-pr: ci-master
ci-release: ci-master

check-env:
ifndef GCP_PROJECT
	$(error GCP_PROJECT is undefined)
endif
ifndef GCP_CLUSTER_NAME
	$(error GCP_CLUSTER_NAME is undefined)
endif