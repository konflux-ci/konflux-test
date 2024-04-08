FROM registry.access.redhat.com/ubi8/ubi-minimal:8.9-1161
RUN rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm && \
    microdnf -y --setopt=tsflags=nodocs install \
    clamav \
    clamd \
    clamav-update && \
    microdnf clean all
RUN freshclam
