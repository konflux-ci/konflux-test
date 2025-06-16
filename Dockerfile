# Build step for check-payload tool
FROM registry.access.redhat.com/ubi9/go-toolset:9.6-1749636489 as check-payload-build

WORKDIR /opt/app-root/src

ARG CHECK_PAYLOAD_VERSION=0.3.7

RUN curl -s -L -o check-payload.tar.gz "https://github.com/openshift/check-payload/archive/refs/tags/${CHECK_PAYLOAD_VERSION}.tar.gz" && \
    tar -xzf check-payload.tar.gz && rm check-payload.tar.gz && cd check-payload-${CHECK_PAYLOAD_VERSION} && \
    CGO_ENABLED=0 go build -ldflags="-X main.Commit=${CHECK_PAYLOAD_VERSION}" -o /opt/app-root/src/check-payload-binary && \
    chmod +x /opt/app-root/src/check-payload-binary

# Container image that runs your code
FROM docker.io/snyk/snyk:linux@sha256:4f8a787fce0a406c5f3bb83fad2903fe06dae90db67bd7e98af3cb90f16b156a as snyk
FROM quay.io/enterprise-contract/ec-cli:snapshot@sha256:6491f75e335015b8e800ca4508ac0cd155aeaf3a89399bc98949f93860a3b0a5 AS ec-cli
FROM ghcr.io/sigstore/cosign/cosign:v99.99.91@sha256:8caf794491167c331776203c60b7c69d4ff24b4b4791eba348d8def0fd0cc343 as cosign-bin
FROM quay.io/konflux-ci/buildah-task:latest@sha256:b82d465a06c926882d02b721cf8a8476048711332749f39926a01089cf85a3f9 AS buildah-task-image
FROM registry.access.redhat.com/ubi9/ubi-minimal:9.6-1749489516

# Note that the version of OPA used by pr-checks must be updated manually to reflect conftest updates
# To find the OPA version associated with conftest run the following with the relevant version of conftest:
# $ conftest --version
ARG conftest_version=0.45.0
ARG BATS_VERSION=1.8.2
ARG sbom_utility_version=0.12.0
ARG OPM_VERSION=v1.40.0
ARG UMOCI_VERSION=v0.4.7

ENV POLICY_PATH="/project"

ADD https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm epel-release-latest-9.noarch.rpm

RUN rpm -Uvh epel-release-latest-9.noarch.rpm && \
    microdnf -y --setopt=tsflags=nodocs --setopt=install_weak_deps=0 install \
    findutils \
    jq \
    skopeo \
    tar \
    python3 \
    clamav \
    clamd \
    csdiff \
    git \
    # Remove golang after https://github.com/openshift/check-payload/issues/231 is resolved
    golang \
    python3-file-magic \
    python3-pip \
    ShellCheck \
    csmock-plugin-shellcheck-core \
    clamav-update && \
    pip3 install --no-cache-dir yq && \
    curl -s -L https://github.com/CycloneDX/sbom-utility/releases/download/v"${sbom_utility_version}"/sbom-utility-v"${sbom_utility_version}"-linux-amd64.tar.gz --output sbom-utility.tar.gz && \
    mkdir sbom-utility && tar -xf sbom-utility.tar.gz -C sbom-utility && rm sbom-utility.tar.gz && \
    cd /usr/bin && \
    microdnf -y install libicu && \
    microdnf clean all

RUN ARCH=$(uname -m) && curl -s -L https://github.com/open-policy-agent/conftest/releases/download/v"${conftest_version}"/conftest_"${conftest_version}"_Linux_"$ARCH".tar.gz | tar -xz --no-same-owner -C /usr/bin/ && \
    curl -L https://mirror.openshift.com/pub/openshift-v4/"$ARCH"/clients/ocp/stable/openshift-client-linux.tar.gz --output oc.tar.gz && tar -xzvf oc.tar.gz -C /usr/bin && rm oc.tar.gz && \
    curl -s -LO "https://github.com/bats-core/bats-core/archive/refs/tags/v$BATS_VERSION.tar.gz" && \
    curl -s -L https://github.com/operator-framework/operator-registry/releases/download/"${OPM_VERSION}"/linux-amd64-opm > /usr/bin/opm && chmod +x /usr/bin/opm && \
    curl -s -L https://github.com/opencontainers/umoci/releases/download/"${UMOCI_VERSION}"/umoci.amd64 > /usr/bin/umoci && chmod +x /usr/bin/umoci && \
    OPA_VERSION=$(/usr/bin/conftest --version | grep OPA | cut -d" " -f2) && curl -L -o /usr/bin/opa https://openpolicyagent.org/downloads/v"${OPA_VERSION}"/opa_linux_amd64_static && chmod +x /usr/bin/opa && \
    tar -xf "v$BATS_VERSION.tar.gz" && \
    cd "bats-core-$BATS_VERSION" && \
    ./install.sh /usr && \
    cd .. && rm -rf "bats-core-$BATS_VERSION" && rm -rf "v$BATS_VERSION.tar.gz" && \
    cd /

ENV PATH="${PATH}:/sbom-utility"

COPY --from=snyk /usr/local/bin/snyk /usr/local/bin/snyk

COPY --from=ec-cli /usr/local/bin/ec /usr/local/bin/ec

COPY --from=cosign-bin /ko-app/cosign /usr/local/bin/cosign

COPY --from=check-payload-build /opt/app-root/src/check-payload-binary /usr/bin/check-payload

COPY --from=buildah-task-image /usr/bin/retry /usr/bin/

COPY policies $POLICY_PATH
COPY test/conftest.sh $POLICY_PATH

# Copies your code file from your action repository to the filesystem path `/` of the container
COPY test/selftest.sh /selftest.sh
COPY test/utils.sh /utils.sh

ENTRYPOINT ["/usr/bin/bash"]
