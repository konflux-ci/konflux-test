FROM registry.access.redhat.com/ubi8/ubi

ARG conftest_version=0.30.0

RUN curl -L https://github.com/open-policy-agent/conftest/releases/download/v"${conftest_version}"/conftest_"${conftest_version}"_Linux_x86_64.tar.gz | tar -xz --no-same-owner -C /usr/bin/ && \
    dnf -y --setopt=tsflags=nodocs install \
    jq \
    skopeo

COPY policies /project