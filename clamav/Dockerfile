FROM registry.access.redhat.com/ubi9/ubi-minimal:9.5-1745855087
FROM quay.io/enterprise-contract/ec-cli:snapshot@sha256:6690bc4d86cedbba5a45f231e9ee2e0542c616064da7bc5fd26af65096215e96 AS ec-cli

ENV POLICY_PATH="/project"
# Install required packages
RUN rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm && \
    microdnf -y --setopt=tsflags=nodocs install \
    clamav \
    clamd \
    clamav-update \
    jq \
    tar \
    skopeo \
    findutils \
    && microdnf clean all

COPY ./test/utils.sh /utils.sh


# Update ClamAV virus definitions
RUN freshclam

COPY clamav/whitelist.ign2 /var/lib/clamav/whitelist.ign2

COPY policies $POLICY_PATH
COPY test/conftest.sh $POLICY_PATH

# Download and install oc
RUN ARCH="$(uname -m)" && \
    curl -fsSL https://mirror.openshift.com/pub/openshift-v4/"$ARCH"/clients/ocp/stable/openshift-client-linux.tar.gz --output oc.tar.gz && \
    cp oc.tar.gz /usr/bin/oc && \
    tar -xzvf oc.tar.gz -C /usr/bin && \
    rm oc.tar.gz

ENTRYPOINT ["/usr/bin/clamscan"]
