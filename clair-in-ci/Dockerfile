FROM quay.io/projectquay/clair-action:v0.0.6

# Update the matcher database. Use the info log level to track sources
RUN DB_PATH=/tmp/matcher.db /bin/clair-action --level info update
