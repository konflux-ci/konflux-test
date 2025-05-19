#!/usr/bin/env bash
set -e

CONF_FILE="/etc/clamd.d/scan.conf"
MAX_THREADS="${MAX_THREADS:-8}" 
SOCKET="/var/run/clamd.scan/clamd.sock"
TIMEOUT=30
elapsed=0

# Update MaxThreads setting in clamd config
if grep -q '^MaxThreads' "$CONF_FILE"; then
  sed -i "s/^MaxThreads.*/MaxThreads $MAX_THREADS/" "$CONF_FILE"
else
  echo "MaxThreads $MAX_THREADS" >> "$CONF_FILE"
fi

# Start clamd in background
echo "Starting clamd ..."
/usr/sbin/clamd -c "${CONF_FILE}" --foreground=false &

# Wait for the socket to be created
while [ ! -S "$SOCKET" ]; do
  sleep 1
  elapsed=$((elapsed + 1))
  if [ "$elapsed" -ge "$TIMEOUT" ]; then
    echo "Failed to start clamd"
    exit 0
  fi
done

echo "clamd is ready!"

# Run the user-provided command (if any)
if [ $# -gt 0 ]; then
  exec "$@"
fi
