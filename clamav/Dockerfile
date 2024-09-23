FROM registry.access.redhat.com/ubi9/ubi-minimal:9.4-1227.1726694542
RUN rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm && \
    microdnf -y --setopt=tsflags=nodocs install \
    clamav \
    clamd \
    clamav-update && \
    microdnf clean all
COPY whitelist.ign2 /var/lib/clamav/whitelist.ign2
RUN freshclam
