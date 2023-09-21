# Container image that runs your code
FROM docker.io/snyk/snyk:linux@sha256:d46a03816a4599e6555cce8d6fc9fd5f4ee4d97f3c1c41ed07ce806c61087733 as snyk
# Note that the version of OPA used by pr-checks must be updated manually to reflect dependabot updates
# To find the OPA version associated with conftest run the following:
# podman run --rm -ti ${NEW_IMAGE}  --version
FROM docker.io/openpolicyagent/conftest:v0.44.1@sha256:93c0fccb97538b24ecb8492c5c988f39d27ec7108d4ce99f217677ad50f4271e as conftest
FROM registry.access.redhat.com/ubi8/ubi-minimal:8.8-1072


ARG BATS_VERSION=1.6.0
ARG cyclonedx_version=0.24.2
ARG sbom_utility_version=0.12.0
ARG OPM_VERSION=v1.26.3

ENV POLICY_PATH="/project"

RUN rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm && \
    microdnf -y --setopt=tsflags=nodocs --setopt=install_weak_deps=0 install \
    jq \
    skopeo \
    tar \
    python39 \
    clamav \
    clamd \
    python39-pip \
    clamav-update && \
    pip3 install --no-cache-dir python-dateutil yq && \
    curl -L https://github.com/CycloneDX/sbom-utility/releases/download/v"${sbom_utility_version}"/sbom-utility-v"${sbom_utility_version}"-linux-amd64.tar.gz --output sbom-utility.tar.gz && \
    mkdir sbom-utility && tar -xf sbom-utility.tar.gz -C sbom-utility && rm sbom-utility.tar.gz && \
    cd /usr/bin && \
    curl -OL https://github.com/CycloneDX/cyclonedx-cli/releases/download/v"${cyclonedx_version}"/cyclonedx-linux-x64 && \
    microdnf -y install libicu && \
    chmod +x cyclonedx-linux-x64 && \
    microdnf clean all

RUN ARCH=$(uname -m) && curl https://mirror.openshift.com/pub/openshift-v4/"$ARCH"/clients/ocp/stable/openshift-client-linux.tar.gz --output oc.tar.gz && tar -xzvf oc.tar.gz -C /usr/bin && rm oc.tar.gz && \
    curl -LO "https://github.com/bats-core/bats-core/archive/refs/tags/v$BATS_VERSION.tar.gz" && \
    curl -L https://github.com/operator-framework/operator-registry/releases/download/"${OPM_VERSION}"/linux-amd64-opm > /usr/bin/opm && chmod +x /usr/bin/opm && \ 
    tar -xf "v$BATS_VERSION.tar.gz" && \
    cd "bats-core-$BATS_VERSION" && \
    ./install.sh /usr && \
    cd .. && rm -rf "bats-core-$BATS_VERSION" && rm -rf "v$BATS_VERSION.tar.gz" && \
    cd /

ENV PATH="${PATH}:/sbom-utility"

COPY --from=snyk /usr/local/bin/snyk /usr/local/bin/snyk
COPY --from=conftest /usr/local/bin/conftest /usr/local/bin/conftest


COPY policies $POLICY_PATH
COPY test/conftest.sh $POLICY_PATH

# Copies your code file from your action repository to the filesystem path `/` of the container
COPY test/selftest.sh /selftest.sh
COPY test/utils.sh /utils.sh

ENTRYPOINT ["/usr/bin/bash"]
