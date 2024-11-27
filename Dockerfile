# Container image that runs your code
FROM docker.io/snyk/snyk:linux@sha256:893db22bae8074744d869f585013d7d7e471531d1287d28ca2f54d356f9be44b as snyk
FROM quay.io/enterprise-contract/ec-cli:snapshot@sha256:dc7d404596385e7d3c624ec0492524a1d57efe2b0c10cf0ec2158d49c0290a83 AS ec-cli
FROM ghcr.io/sigstore/cosign/cosign:v99.99.91@sha256:8caf794491167c331776203c60b7c69d4ff24b4b4791eba348d8def0fd0cc343 as cosign-bin

FROM registry.access.redhat.com/ubi9/ubi:9.4-1214.1729773476 AS src

ARG TARGETARCH
# Note that the version of OPA used by pr-checks must be updated manually to reflect conftest updates
# To find the OPA version associated with conftest run the following with the relevant version of conftest:
# $ conftest --version
ARG CONFTEST_VERSION=0.45.0
ARG SBOM_UTILITY_VERSION=0.12.0
ARG BATS_VERSION=1.6.0
ARG OPM_VERSION=v1.40.0
ARG UMOCI_VERSION=v0.4.7

ADD https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm /tmp/epel-release-latest-9.noarch.rpm

ADD https://github.com/open-policy-agent/conftest/releases/download/v"${CONFTEST_VERSION}"/conftest_"${CONFTEST_VERSION}"_Linux_"${TARGETARCH/amd64/x86_64}".tar.gz /src/conftest.tar.gz
ADD https://github.com/CycloneDX/sbom-utility/releases/download/v"${SBOM_UTILITY_VERSION}"/sbom-utility-v"${SBOM_UTILITY_VERSION}"-linux-"${TARGETARCH/ppc64le/ppc64}".tar.gz /src/sbom-utility.tar.gz
ADD https://mirror.openshift.com/pub/openshift-v4/"${TARGETARCH}"/clients/ocp/stable/openshift-client-linux.tar.gz /src/oc.tar.gz
ADD https://github.com/bats-core/bats-core/archive/refs/tags/v"${BATS_VERSION}".tar.gz /src/bats.tar.gz

ADD --chmod=744 https://github.com/operator-framework/operator-registry/releases/download/"${OPM_VERSION}"/linux-"${TARGETARCH}"-opm /usr/local/bin/opm
ADD --chmod=744 https://github.com/opencontainers/umoci/releases/download/"${UMOCI_VERSION}"/umoci.amd64 /usr/local/bin/umoci

RUN tar -xvzf src/conftest.tar.gz -C /usr/local/bin/ && chmod +x /usr/local/bin/conftest && \
    tar -xvzf src/sbom-utility.tar.gz -C /usr/local/bin/ && chmod +x /usr/local/bin/sbom-utility && \
    tar -xvzf src/oc.tar.gz -C /usr/local/bin/ && chmod +x /usr/local/bin/oc && \
    tar -xvzf src/bats.tar.gz -C /tmp/

FROM registry.access.redhat.com/ubi9/ubi-minimal:9.4-1227.1726694542

ARG BATS_VERSION=1.6.0

ENV POLICY_PATH="/project"

COPY --from=src /usr/local/bin/ /usr/local/bin/
COPY --from=src /tmp/ /tmp/

RUN rpm -Uvh /tmp/epel-release-latest-9.noarch.rpm && \
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
    python3-file-magic \
    python3-pip \
    ShellCheck \
    csmock-plugin-shellcheck-core \
    clamav-update && \
    pip3 install --no-cache-dir yq && \
    microdnf -y install libicu && \
    microdnf clean all && \
    cd /tmp/"bats-core-$BATS_VERSION" && ./install.sh /usr && \
    cd .. && rm -rf /tmp/*

COPY --from=snyk /usr/local/bin/snyk /usr/local/bin/snyk

COPY --from=ec-cli /usr/local/bin/ec /usr/local/bin/ec

COPY --from=cosign-bin /ko-app/cosign /usr/local/bin/cosign

COPY policies $POLICY_PATH
COPY test/conftest.sh $POLICY_PATH

# Copies your code file from your action repository to the filesystem path `/` of the container
COPY test/selftest.sh /selftest.sh
COPY test/utils.sh /utils.sh

ENTRYPOINT ["/usr/bin/bash"]
