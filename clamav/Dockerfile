FROM registry.access.redhat.com/ubi8/ubi-minimal:8.9-1161.1715068733
RUN rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm && \
    microdnf -y --setopt=tsflags=nodocs install \
    clamav \
    clamd \
    clamav-update && \
    microdnf clean all
COPY whitelist.ign2 /var/lib/clamav/whitelist.ign2
RUN freshclam
