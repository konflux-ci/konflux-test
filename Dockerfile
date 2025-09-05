# Build step for check-payload tool
FROM registry.access.redhat.com/ubi9/go-toolset:9.6-1756913080 as check-payload-build

#check-payload
WORKDIR /opt/app-root/src
ARG CHECK_PAYLOAD_VERSION=0.3.10

RUN tar -xzf /cachi2/output/deps/generic/check-payload-${CHECK_PAYLOAD_VERSION}.tar.gz &&  cd check-payload-${CHECK_PAYLOAD_VERSION} && \
    CGO_ENABLED=0 go build -ldflags="-X main.Commit=${CHECK_PAYLOAD_VERSION}" -o /opt/app-root/src/check-payload-binary && \
    chmod +x /opt/app-root/src/check-payload-binary

FROM quay.io/konflux-ci/buildah-task:latest@sha256:cb58912cc9aecdb4c64e353ac44d0586574e89ba6cec2f2b191b4eeb98c6f81e AS buildah-task-image
FROM registry.redhat.io/openshift4/ose-tools-rhel9@sha256:ea1416d4260cc62a830c013754ae9720561b1e6c9c8da0e198ebae67783e8a1c as oc-bin
FROM registry.access.redhat.com/ubi9/ubi:9.6-1756915113

# Note that the version of OPA used by pr-checks must be updated manually to reflect conftest updates
# To find the OPA version associated with conftest run the following with the relevant version of conftest:
# $ conftest --version
ARG BATS_VERSION=1.8.2

ARG PATH_TO_ART=/cachi2/output/deps/generic

ENV POLICY_PATH="/project"

# Detect architecture for multi-arch support
ARG TARGETARCH
ARG TARGETOS

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
    golang \
    python3-file-magic \
    python3-pip \
    clamav-update \
    ShellCheck \
    csmock-plugin-shellcheck-core \
    libicu && \
    # Use architecture-specific binaries and sbom-utility
    if [ "$TARGETARCH" = "amd64" ]; then \
        mkdir sbom-utility && tar -xf ${PATH_TO_ART}/sbom-utility.tar.gz -C sbom-utility && \
        cp ${PATH_TO_ART}/linux-amd64-opm /usr/bin/opm && \
        cp ${PATH_TO_ART}/umoci.linux.amd64 /usr/bin/umoci && \
        cp ${PATH_TO_ART}/opa_linux_amd64_static /usr/bin/opa && \
        cp ${PATH_TO_ART}/snyk-linux /usr/local/bin/snyk && \
        cp ${PATH_TO_ART}/ec_linux_amd64 /usr/local/bin/ec && \
        cp ${PATH_TO_ART}/cosign-linux-amd64 /usr/local/bin/cosign && \
        tar -xzf ${PATH_TO_ART}/conftest_0.45.0_Linux_x86_64.tar.gz -C /usr/bin/; \
    elif [ "$TARGETARCH" = "arm64" ]; then \
        mkdir sbom-utility && tar -xf ${PATH_TO_ART}/sbom-utility-arm64.tar.gz -C sbom-utility && \
        cp ${PATH_TO_ART}/linux-arm64-opm /usr/bin/opm && \
        cp ${PATH_TO_ART}/umoci.linux.arm64 /usr/bin/umoci && \
        cp ${PATH_TO_ART}/opa_linux_arm64_static /usr/bin/opa && \
        cp ${PATH_TO_ART}/snyk-linux-arm64 /usr/local/bin/snyk && \
        cp ${PATH_TO_ART}/ec_linux_arm64 /usr/local/bin/ec && \
        cp ${PATH_TO_ART}/cosign-linux-arm64 /usr/local/bin/cosign && \
        tar -xzf ${PATH_TO_ART}/conftest_0.45.0_Linux_arm64.tar.gz -C /usr/bin/; \
    fi && \
    chmod +x /usr/bin/opm /usr/bin/umoci /usr/bin/opa /usr/local/bin/snyk /usr/local/bin/ec /usr/local/bin/cosign && \
    tar -xf ${PATH_TO_ART}/v1.8.2.tar.gz && \
    cd "bats-core-$BATS_VERSION" && \
    ./install.sh /usr && \
    cd .. && rm -rf "bats-core-$BATS_VERSION" && \
    cd / && \
    dnf clean all

#yq install, oneline because its pip
# Use architecture-specific Python wheels for PyYAML, architecture-agnostic for others
RUN if [ "$TARGETARCH" = "amd64" ]; then \
        PYTHON_PYYAML_WHEEL="PyYAML-6.0.2-cp39-cp39-manylinux_2_17_x86_64.manylinux2014_x86_64.whl"; \
    elif [ "$TARGETARCH" = "arm64" ]; then \
        PYTHON_PYYAML_WHEEL="PyYAML-6.0.2-cp39-cp39-manylinux_2_17_aarch64.manylinux2014_aarch64.whl"; \
    fi && \
    pip install --no-cache-dir "${PATH_TO_ART}/${PYTHON_PYYAML_WHEEL}" "${PATH_TO_ART}/argcomplete-3.6.2-py3-none-any.whl" "${PATH_TO_ART}/tomlkit-0.13.3-py3-none-any.whl" "${PATH_TO_ART}/xmltodict-0.14.2-py2.py3-none-any.whl" "${PATH_TO_ART}/yq-3.4.3-py3-none-any.whl"

ENV PATH="${PATH}:/sbom-utility"

COPY --from=check-payload-build /opt/app-root/src/check-payload-binary /usr/bin/check-payload

COPY --from=oc-bin /usr/bin/oc /usr/bin/

COPY --from=buildah-task-image /usr/bin/retry /usr/bin/

COPY policies $POLICY_PATH
COPY test/conftest.sh $POLICY_PATH

# Copies your code file from your action repository to the filesystem path `/` of the container
COPY test/selftest.sh /selftest.sh
COPY test/utils.sh /utils.sh

ENTRYPOINT ["/usr/bin/bash"]
