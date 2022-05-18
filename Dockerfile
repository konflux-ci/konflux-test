# Container image that runs your code
FROM registry.access.redhat.com/ubi8/ubi

ARG conftest_version=0.30.0
ARG BATS_VERSION=1.6.0
ARG go_version=1.18.1
ARG gosec_version=2.11.0

ENV POLICY_PATH="/project"

RUN curl -L https://github.com/open-policy-agent/conftest/releases/download/v"${conftest_version}"/conftest_"${conftest_version}"_Linux_x86_64.tar.gz | tar -xz --no-same-owner -C /usr/bin/ && \
    curl -LO "https://github.com/bats-core/bats-core/archive/refs/tags/v$BATS_VERSION.tar.gz" && \
    tar -xf "v$BATS_VERSION.tar.gz" && \
    cd "bats-core-$BATS_VERSION" && \
    ./install.sh /usr && \
    cd .. | rm -rf "bats-core-$BATS_VERSION" | rm -rf "v$BATS_VERSION.tar.gz" && \
    curl -L https://go.dev/dl/go"${go_version}".linux-amd64.tar.gz | tar -xz --no-same-owner -C /usr/local/ && \
    curl -sfL https://raw.githubusercontent.com/securego/gosec/master/install.sh | sh -s -- -b /usr/local/go/bin v"${gosec_version}" && \
    dnf -y --setopt=tsflags=nodocs install \
    jq \
    skopeo 

ENV PATH $PATH:/usr/local/go/bin

COPY policies $POLICY_PATH
COPY test/conftest.sh $POLICY_PATH

# Copies your code file from your action repository to the filesystem path `/` of the container
COPY test/entrypoint.sh /entrypoint.sh

# Code file to execute when the docker container starts up (`entrypoint.sh`)
ENTRYPOINT ["/entrypoint.sh"]
