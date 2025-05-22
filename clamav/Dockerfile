FROM registry.access.redhat.com/ubi9/ubi-minimal:9.6-1747218906
FROM quay.io/enterprise-contract/ec-cli:snapshot@sha256:06026ad674b90dec8b3795f10aa3cd0aa98be4640e7b8c19965644ef4d7c2023 AS ec-cli

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
