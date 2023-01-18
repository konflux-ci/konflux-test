FROM registry.access.redhat.com/ubi8/ubi:8.7
RUN dnf -y --setopt=tsflags=nodocs install \
    https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm && \
    dnf -y --setopt=tsflags=nodocs install \
    clamav \
    clamd \
    clamav-update && \
    dnf clean all
RUN freshclam
