# Build step for check-payload tool
FROM registry.access.redhat.com/ubi9/go-toolset:9.6-1752083840 as check-payload-build

#check-payload
WORKDIR /opt/app-root/src
ARG CHECK_PAYLOAD_VERSION=0.3.6

RUN tar -xzf /cachi2/output/deps/generic/check-payload.tar.gz &&  cd check-payload-${CHECK_PAYLOAD_VERSION} && \
    CGO_ENABLED=0 go build -ldflags="-X main.Commit=${CHECK_PAYLOAD_VERSION}" -o /opt/app-root/src/check-payload-binary && \
    chmod +x /opt/app-root/src/check-payload-binary 
# Container image that runs your code
FROM docker.io/snyk/snyk:linux@sha256:4a32a3e5419bbb583ad48c53a48062274f668da4d0cf6a1a9a16dabdaa3a3726 as snyk
FROM quay.io/conforma/cli:snapshot@sha256:ec28a60768149d322a918add7dcf3077ea7336da8780811921a246f5066ea97d AS conforma
FROM registry.redhat.io/rhtas/cosign-rhel9@sha256:cb53dcc3bc912dd7f12147f33af1b435eae5ff4ab83b85c0277b4004b20a0248 as cosign-bin
FROM quay.io/konflux-ci/buildah-task:latest@sha256:c8d667a4efa2f05e73e2ac36b55928633d78857589165bd919d2628812d7ffcb AS buildah-task-image
FROM quay.io/appuio/oc:v4.18 AS oc-bin
FROM registry.access.redhat.com/ubi9/ubi:9.6-1752069608

# Note that the version of OPA used by pr-checks must be updated manually to reflect conftest updates
# To find the OPA version associated with conftest run the following with the relevant version of conftest:
# $ conftest --version
ARG BATS_VERSION=1.8.2

ARG PATH_TO_ART=/cachi2/output/deps/generic

ENV POLICY_PATH="/project"


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

COPY --from=conforma /usr/local/bin/ec /usr/local/bin/ec

COPY --from=cosign-bin /usr/local/bin/cosign /usr/local/bin/cosign

COPY --from=oc-bin /bin/oc /usr/bin/

COPY --from=buildah-task-image /usr/bin/retry /usr/bin/

COPY policies $POLICY_PATH
COPY test/conftest.sh $POLICY_PATH

# Copies your code file from your action repository to the filesystem path `/` of the container
COPY test/selftest.sh /selftest.sh
COPY test/utils.sh /utils.sh

ENTRYPOINT ["/usr/bin/bash"]
