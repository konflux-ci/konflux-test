FROM quay.io/crozzy/clair-action:v0
RUN microdnf install wget zstd -y && wget -q https://clair-sqlite-db.s3.amazonaws.com/matcher.zst && zstd -o /tmp/matcher.db -d matcher.zst && rm -f matcher.zst && \
    microdnf clean all