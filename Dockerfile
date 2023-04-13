# Container image that runs your code
FROM docker.io/snyk/snyk:linux@sha256:6ef20869b991ace2e55581f922f24ab909c54b5ff0e5acd3b8000dab5f639f35 as snyk
FROM registry.access.redhat.com/ubi8/ubi:8.7-1112

ARG conftest_version=0.33.2
ARG BATS_VERSION=1.6.0
ARG cyclonedx_version=0.24.2
ARG OPM_VERSION=v1.26.3

ENV POLICY_PATH="/project"

RUN ARCH=$(uname -m) && curl -L https://github.com/open-policy-agent/conftest/releases/download/v"${conftest_version}"/conftest_"${conftest_version}"_Linux_"$ARCH".tar.gz | tar -xz --no-same-owner -C /usr/bin/ && \
    curl https://mirror.openshift.com/pub/openshift-v4/"$ARCH"/clients/ocp/stable/openshift-client-linux.tar.gz --output oc.tar.gz && tar -xzvf oc.tar.gz -C /usr/bin && rm oc.tar.gz && \
    curl -LO "https://github.com/bats-core/bats-core/archive/refs/tags/v$BATS_VERSION.tar.gz" && \
    curl -L https://github.com/operator-framework/operator-registry/releases/download/"${OPM_VERSION}"/linux-amd64-opm > /usr/bin/opm && chmod +x /usr/bin/opm && \ 
    curl "https://bootstrap.pypa.io/get-pip.py" -o "get-pip.py" && \
    tar -xf "v$BATS_VERSION.tar.gz" && \
    cd "bats-core-$BATS_VERSION" && \
    ./install.sh /usr && \
    cd .. && rm -rf "bats-core-$BATS_VERSION" && rm -rf "v$BATS_VERSION.tar.gz" && \
    dnf -y --setopt=tsflags=nodocs install \
    jq \
    skopeo \
    python39 \
    https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm && \
    dnf -y --setopt=tsflags=nodocs install \
    clamav \
    clamd \
    clamav-update && \
    cd / && \
    python3.9 get-pip.py && \
    pip install --no-cache-dir python-dateutil yq && \
    cd /usr/bin && \
    curl -OL https://github.com/CycloneDX/cyclonedx-cli/releases/download/v"${cyclonedx_version}"/cyclonedx-linux-x64 && \
    dnf -y install libicu && \
    chmod +x cyclonedx-linux-x64 && \
    dnf clean all

COPY --from=snyk /usr/local/bin/snyk /usr/local/bin/snyk

COPY policies $POLICY_PATH
COPY test/conftest.sh $POLICY_PATH

# Copies your code file from your action repository to the filesystem path `/` of the container
COPY test/selftest.sh /selftest.sh
COPY test/utils.sh /utils.sh

ENTRYPOINT ["/usr/bin/bash"]
