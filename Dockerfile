# Container image that runs your code
FROM registry.access.redhat.com/ubi8/ubi

ARG conftest_version=0.30.0
ARG BATS_VERSION=1.6.0

ENV POLICY_PATH="/project"

RUN curl -L https://github.com/open-policy-agent/conftest/releases/download/v"${conftest_version}"/conftest_"${conftest_version}"_Linux_x86_64.tar.gz | tar -xz --no-same-owner -C /usr/bin/ && \
    curl https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/stable/openshift-client-linux.tar.gz --output oc.tar.gz && tar -xzvf oc.tar.gz -C /usr/bin && \
    curl -LO "https://github.com/bats-core/bats-core/archive/refs/tags/v$BATS_VERSION.tar.gz" && \
    tar -xf "v$BATS_VERSION.tar.gz" && \
    cd "bats-core-$BATS_VERSION" && \
    ./install.sh /usr && \
    cd .. | rm -rf "bats-core-$BATS_VERSION" | rm -rf "v$BATS_VERSION.tar.gz" && \
    dnf -y --setopt=tsflags=nodocs install \
    jq \
    skopeo \
    python39 \
    https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm && \
    dnf -y --setopt=tsflags=nodocs install \
    clamav \
    clamd \
    clamav-update

COPY policies $POLICY_PATH
COPY test/conftest.sh $POLICY_PATH

# Copies your code file from your action repository to the filesystem path `/` of the container
COPY test/entrypoint.sh /entrypoint.sh

# Code file to execute when the docker container starts up (`entrypoint.sh`)
ENTRYPOINT ["/entrypoint.sh"]
