FROM registry.access.redhat.com/ubi9/go-toolset:9.6-1747333074 as check-payload-build

#check-payload
WORKDIR /opt/app-root/src
ARG CHECK_PAYLOAD_VERSION=0.3.6

RUN tar -xzf /cachi2/output/deps/generic/check-payload.tar.gz &&  cd check-payload-${CHECK_PAYLOAD_VERSION} && \
    CGO_ENABLED=0 go build -ldflags="-X main.Commit=${CHECK_PAYLOAD_VERSION}" -o /opt/app-root/src/check-payload-binary && \
    chmod +x /opt/app-root/src/check-payload-binary 
# Container image that runs your code
FROM docker.io/snyk/snyk:linux@sha256:dc9e992010878db3e67392f432694392bd610189da68bab340363fdba84acfb9 as snyk
FROM quay.io/enterprise-contract/ec-cli:snapshot@sha256:6491f75e335015b8e800ca4508ac0cd155aeaf3a89399bc98949f93860a3b0a5 AS ec-cli
FROM ghcr.io/sigstore/cosign/cosign:v99.99.91@sha256:8caf794491167c331776203c60b7c69d4ff24b4b4791eba348d8def0fd0cc343 as cosign-bin
FROM quay.io/konflux-ci/buildah-task:latest@sha256:b82d465a06c926882d02b721cf8a8476048711332749f39926a01089cf85a3f9 AS buildah-task-image
FROM quay.io/appuio/oc:v4.18 AS oc-bin
FROM registry.access.redhat.com/ubi9/ubi:9.6-1747219013

# Note that the version of OPA used by pr-checks must be updated manually to reflect conftest updates
# To find the OPA version associated with conftest run the following with the relevant version of conftest:
# $ conftest --version
ARG BATS_VERSION=1.8.2

ARG PATH_TO_ART=/cachi2/output/deps/generic

ENV POLICY_PATH="/project"

#ADD https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm epel-release-latest-9.noarch.rpm

# Build dependency offline to streamline build
#rpm -Uvh epel-release-latest-9.noarch.rpm && \
RUN dnf install -y --nogpgcheck jq \
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
    clamav-update \
    ShellCheck \
    csmock-plugin-shellcheck-core \
    libicu && \
    mkdir sbom-utility && tar -xf ${PATH_TO_ART}/sbom-utility.tar.gz -C sbom-utility && \
    cp ${PATH_TO_ART}/linux-amd64-opm /usr/bin/opm && chmod +x /usr/bin/opm && \
    cp ${PATH_TO_ART}/umoci.amd64 /usr/bin/umoci && chmod +x /usr/bin/umoci && \
    cp ${PATH_TO_ART}/opa_linux_amd64_static /usr/bin/opa && chmod +x /usr/bin/opa && \
    tar -xzf ${PATH_TO_ART}/conftest_0.45.0_Linux_x86_64.tar.gz -C /usr/bin/ && \
    tar -xf ${PATH_TO_ART}/v1.8.2.tar.gz && \
    cd "bats-core-$BATS_VERSION" && \
    ./install.sh /usr && \
    cd .. && rm -rf "bats-core-$BATS_VERSION" && \
    cd / && \
    dnf clean all

#yq install, oneline because its pip
RUN pip install --no-cache-dir ${PATH_TO_ART}/PyYAML-6.0.2-cp39-cp39-manylinux_2_17_x86_64.manylinux2014_x86_64.whl ${PATH_TO_ART}/argcomplete-3.6.2-py3-none-any.whl ${PATH_TO_ART}/tomlkit-0.13.3-py3-none-any.whl ${PATH_TO_ART}/xmltodict-0.14.2-py2.py3-none-any.whl ${PATH_TO_ART}/yq-3.4.3-py3-none-any.whl

ENV PATH="${PATH}:/sbom-utility"

COPY --from=check-payload-build /opt/app-root/src/check-payload-binary /usr/bin/check-payload

COPY --from=snyk /usr/local/bin/snyk /usr/local/bin/snyk

COPY --from=ec-cli /usr/local/bin/ec /usr/local/bin/ec

COPY --from=cosign-bin /ko-app/cosign /usr/local/bin/cosign

COPY --from=oc-bin /bin/oc /usr/bin/

COPY --from=buildah-task-image /usr/bin/retry /usr/bin/

COPY policies $POLICY_PATH
COPY test/conftest.sh $POLICY_PATH

# Copies your code file from your action repository to the filesystem path `/` of the container
COPY test/selftest.sh /selftest.sh
COPY test/utils.sh /utils.sh

ENTRYPOINT ["/usr/bin/bash"]
