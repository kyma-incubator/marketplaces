FROM eu.gcr.io/kyma-project/test-infra/alpine-kubectl:v20200121-4f3202bd

ARG KYMA_VERSION
ARG INITIALIZER_VERSION

ENV KYMA_VERSION ${KYMA_VERSION}
ENV INITIALIZER_VERSION ${INITIALIZER_VERSION}
ENV TILLER_RESOURCE "tiller.yaml"
ENV KYMA_INSTALLER_RESOURCE "kyma-installer-cluster.yaml"

RUN mkdir -p /initializer/scripts
WORKDIR /initializer

RUN curl https://raw.githubusercontent.com/kyma-project/kyma/${KYMA_VERSION}/installation/resources/tiller.yaml --output ${TILLER_RESOURCE} --fail -L \
    && curl https://github.com/kyma-project/kyma/releases/download/${KYMA_VERSION}/kyma-installer-cluster.yaml --output ${KYMA_INSTALLER_RESOURCE} --fail -L

COPY scripts/*  scripts/

ENTRYPOINT ["scripts/deploy.sh"]
