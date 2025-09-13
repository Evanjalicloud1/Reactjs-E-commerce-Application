#!/usr/bin/env bash
set -euo pipefail

# deploy.sh -- pull an image and run it on host port 80
# Usage: ./deploy.sh <image> [container_name] [host_port:container_port]
# Examples:
#   ./deploy.sh evanjali1468/dev:latest
#   ./deploy.sh evanjali1468/prod:latest react-trendstore
#   ./deploy.sh evanjali1468/dev:latest react-trendstore 8080:80

IMAGE="${1:-}"
CONTAINER_NAME="${2:-react-trendstore}"
PORT_MAP="${3:-80:80}"
RETRY_PULL=${RETRY_PULL:-3}
SLEEP_AFTER_RUN=3   # seconds to wait before checking container status

if [ -z "$IMAGE" ]; then
  echo "Usage: $0 <docker-image> [container_name] [host_port:container_port]"
  echo "Example: $0 evanjali1468/dev:latest"
  exit 1
fi

# helper for error reporting
trap 'echo "ERROR: command failed on line $LINENO"; exit 1' ERR

echo "[$(date -u +'%Y-%m-%dT%H:%M:%SZ')] Deploy script started"
echo "Image:       $IMAGE"
echo "Container:   $CONTAINER_NAME"
echo "Port map:    $PORT_MAP"

# 0) check docker is available
if ! command -v docker >/dev/null 2>&1; then
  echo "Docker CLI not found. Please install Docker and make sure this user can run docker."
  exit 2
fi

# 1) pull the image (with a few retries)
echo "Pulling image: $IMAGE"
attempt=1
until docker pull "$IMAGE"; do
  if [ $attempt -ge $RETRY_PULL ]; then
    echo "Failed to pull $IMAGE after $RETRY_PULL attempts"
    exit 3
  fi
  echo "Pull failed, retrying ($attempt/$RETRY_PULL) ..."
  attempt=$((attempt+1))
  sleep 2
done

# 2) if an existing container exists, create a lightweight backup image (optional) and remove it
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}\$"; then
  echo "Found existing container: ${CONTAINER_NAME}"
  # create a backup image (timestamped) so you can restore if needed
  BACKUP_TAG="backup-${CONTAINER_NAME}:$(date +%Y%m%d%H%M%S)"
  echo "Creating backup image ${BACKUP_TAG} from running container (if any)..."
  cid=$(docker ps -q -f "name=^${CONTAINER_NAME}$" | head -n1 || true)
  if [ -n "$cid" ]; then
    docker commit "$cid" "${BACKUP_TAG}" >/dev/null && echo "Backup created: ${BACKUP_TAG}" || echo "Backup creation failed (continuing)"
  else
    echo "No running container instance to commit (may be stopped)."
  fi

  echo "Stopping and forcibly removing existing container: ${CONTAINER_NAME}"
  docker rm -f "${CONTAINER_NAME}" 2>/dev/null || true
else
  echo "No existing container named ${CONTAINER_NAME} found"
fi

# 3) start the container
echo "Starting container ${CONTAINER_NAME} -> ${PORT_MAP}"
docker run -d --name "${CONTAINER_NAME}" --restart unless-stopped -p "${PORT_MAP}" "${IMAGE}"

# 4) wait briefly and verify the container is running and port bound
echo "Waiting ${SLEEP_AFTER_RUN}s for container to initialize..."
sleep "${SLEEP_AFTER_RUN}"

# verify container is running
if docker ps --filter "name=^${CONTAINER_NAME}$" --filter "status=running" --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}\$"; then
  echo "Container ${CONTAINER_NAME} is running."
else
  echo "Container ${CONTAINER_NAME} is not running. Checking logs..."
  docker logs --tail 200 "${CONTAINER_NAME}" || true
  echo "Deployment failed: container did not remain running"
  exit 4
fi

# verify host port bound (best-effort)
HOST_PORT="${PORT_MAP%%:*}"
if command -v ss >/dev/null 2>&1; then
  if ss -ltnp | grep -q ":${HOST_PORT} "; then
    echo "Host port ${HOST_PORT} is listening (OK)."
  else
    echo "Warning: host port ${HOST_PORT} does not appear to be listening. Check container and firewall/security group."
  fi
elif command -v netstat >/dev/null 2>&1; then
  if netstat -ltnp | grep -q ":${HOST_PORT} "; then
    echo "Host port ${HOST_PORT} is listening (OK)."
  else
    echo "Warning: host port ${HOST_PORT} does not appear to be listening. Check container and firewall/security group."
  fi
else
  echo "Note: cannot verify host port because neither ss nor netstat is available."
fi

echo "Deployment finished. Container ${CONTAINER_NAME} is running and mapped to host port ${HOST_PORT}."
echo "[$(date -u +'%Y-%m-%dT%H:%M:%SZ')] Deploy script completed successfully."
