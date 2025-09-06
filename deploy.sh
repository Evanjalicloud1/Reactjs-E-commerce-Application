#!/usr/bin/env bash
set -euo pipefail

# deploy.sh -- pull an image and run it on port 80
# Usage: ./deploy.sh <image> [container_name]
# Example: ./deploy.sh evanjali1468/dev:latest
# Example (custom container name): ./deploy.sh evanjali1468/prod:latest react-trendstore

IMAGE="${1:-}"
CONTAINER_NAME="${2:-react-trendstore}"

if [ -z "$IMAGE" ]; then
  echo "Usage: $0 <docker-image> [container_name]"
  echo "Example: $0 evanjali1468/dev:latest"
  exit 1
fi

echo "Pulling image: $IMAGE"
docker pull "$IMAGE"

echo "Stopping and removing existing container (if any): $CONTAINER_NAME"
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}\$"; then
  docker rm -f "${CONTAINER_NAME}" || true
fi

echo "Starting container ${CONTAINER_NAME} -> port 80"
# run in detached mode, restart unless-stopped, map host port 80 to container 80
docker run -d \
  --name "${CONTAINER_NAME}" \
  --restart unless-stopped \
  -p 80:80 \
  "$IMAGE"

echo "Deployment finished. Container ${CONTAINER_NAME} is running and mapped to host port 80."
