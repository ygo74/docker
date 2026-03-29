#!/bin/sh
set -e

echo "Checking cluster state..."
sleep 2

CLUSTER_STATE=$(redis-cli -h 172.30.0.11 -p 6379 cluster info 2>/dev/null | grep cluster_state | cut -d: -f2 | tr -d '\r\n')

echo "Detected cluster_state: '${CLUSTER_STATE}'"

if [ "$CLUSTER_STATE" = "ok" ]; then
  echo "Cluster already exists and is healthy. Skipping creation."
  redis-cli -h 172.30.0.11 -p 6379 cluster nodes
else
  echo "Creating new cluster..."
  redis-cli --cluster create \
    172.30.0.11:6379 \
    172.30.0.12:6379 \
    172.30.0.13:6379 \
    --cluster-replicas 0 --cluster-yes
  echo "Redis cluster created successfully."
fi
