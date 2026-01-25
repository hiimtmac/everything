#!/bin/sh
set -e

NAMESPACE=${DEFAULT_NAMESPACE:-default}
TEMPORAL_ADDRESS=${TEMPORAL_ADDRESS:-temporal:7233}

echo "Waiting for Temporal server to be ready..."
max_attempts=30
attempt=0

until temporal operator cluster health --address $TEMPORAL_ADDRESS 2>/dev/null; do
  attempt=$((attempt + 1))
  if [ $attempt -ge $max_attempts ]; then
    echo "Server did not become healthy after $max_attempts attempts"
    exit 1
  fi
  echo "Server not ready yet, waiting... (attempt $attempt/$max_attempts)"
  sleep 5
done

echo "Server is healthy, creating namespace '$NAMESPACE'..."
temporal operator namespace describe -n $NAMESPACE --address $TEMPORAL_ADDRESS 2>/dev/null || \
  temporal operator namespace create -n $NAMESPACE --address $TEMPORAL_ADDRESS
echo "Namespace '$NAMESPACE' is ready"
