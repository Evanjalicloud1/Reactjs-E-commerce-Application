#!/usr/bin/env bash
set -euo pipefail

# deploy.sh -- pull an image and run it on host port (default 80)
# Usage: ./deploy.sh <image> [container_name] [host_port:container_port]
# Examples:
#   ./deploy.sh evanjali1468/dev:latest
#   ./deploy.sh evanjali1468/prod:latest react-trendstore
#   ./deploy.sh evanjali1468/dev:latest react-trendstore 8080:80

IMAGE="${1:-}"
CONTAINER_NAME="${2:-react-ecom}"
PORT_MAP="${3:-80:80}"
RETRY_PULL=${RETRY_PULL:-3}
SLEEP_AFTER_RUN=${SLEEP_AFTER_RUN:-3}   # seconds to wait before checking container status

if [ -z "$IMAGE" ]; then
  echo "Usage: $0 <docker-image> [container_name] [host_port:container_port]"
  echo "Example: $0 evanjali1468/dev:latest"
  exit 1
fi

# helper for error reporting
trap 'echo "ERROR: command failed on line $LINENO"; exit 1' ERR

timestamp() { date -u +'%Y-%m-%dT%H:%M:%SZ'; }

echo "[$(timestamp)] Deploy script started"
echo "Image:       $IMAGE"
echo "Container:   $CONTAINER_NAME"
echo "Port map:    $PORT_MAP"

# Use DOCKER_CMD as docker or sudo docker if needed
DOCKER_CMD="docker"
if ! command -v docker >/dev/null 2>&1; then
  echo "Docker CLI not found in PATH. Please install Docker."
  exit 2
fi

# check if current user can access docker socket; if not, prefer sudo
if ! docker info >/dev/null 2>&1; then
  if sudo -n true 2>/dev/null; then
    echo "Docker access requires sudo; using sudo for docker commands"
    DOCKER_CMD="sudo docker"
  else
    echo "Current user cannot access Docker daemon and sudo is not available without password."
    echo "Either add this user to the docker group or run this script as root/sudo."
    exit 2
  fi
fi

# 1) pull the image (with retries)
echo "[$(timestamp)] Pulling image: $IMAGE"
attempt=1
until $DOCKER_CMD pull "$IMAGE"; do
  if [ $attempt -ge $RETRY_PULL ]; then
    echo "[$(timestamp)] Failed to pull $IMAGE after $RETRY_PULL attempts"
    exit 3
  fi
  echo "[$(timestamp)] Pull failed, retrying ($attempt/$RETRY_PULL) ..."
  attempt=$((attempt+1))
  sleep 2
done

# 2) if existing container exists, create an optional backup and remove it
if $DOCKER_CMD ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}\$"; then
  echo "[$(timestamp)] Found existing container: ${CONTAINER_NAME}"
  # create a backup image (timestamped)
  BACKUP_TAG="backup-${CONTAINER_NAME}:$(date +%Y%m%d%H%M%S)"
  echo "[$(timestamp)] Creating backup image ${BACKUP_TAG} from running container (if any)..."
  cid=$($DOCKER_CMD ps -q -f "name=^${CONTAINER_NAME}$" | head -n1 || true)
  if [ -n "$cid" ]; then
    $DOCKER_CMD commit "$cid" "${BACKUP_TAG}" >/dev/null && echo "[$(timestamp)] Backup created: ${BACKUP_TAG}" || echo "[$(timestamp)] Backup creation failed (continuing)"
  else
    echo "[$(timestamp)] No running container instance to commit (may be stopped)."
  fi

  echo "[$(timestamp)] Stopping and forcibly removing existing container: ${CONTAINER_NAME}"
  $DOCKER_CMD rm -f "${CONTAINER_NAME}" 2>/dev/null || true
else
  echo "[$(timestamp)] No existing container named ${CONTAINER_NAME} found"
fi

# 3) start the container
echo "[$(timestamp)] Starting container ${CONTAINER_NAME} -> ${PORT_MAP}"
$DOCKER_CMD run -d --name "${CONTAINER_NAME}" --restart unless-stopped -p "${PORT_MAP}" "${IMAGE}"

# 4) wait briefly and verify container is running and port bound
echo "[$(timestamp)] Waiting ${SLEEP_AFTER_RUN}s for container to initialize..."
sleep "${SLEEP_AFTER_RUN}"

# verify container is running
if $DOCKER_CMD ps --filter "name=^${CONTAINER_NAME}$" --filter "status=running" --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}\$"; then
  echo "[$(timestamp)] Container ${CONTAINER_NAME} is running."
else
  echo "[$(timestamp)] Container ${CONTAINER_NAME} is not running. Showing last logs..."
  $DOCKER_CMD logs --tail 200 "${CONTAINER_NAME}" || true
  echo "[$(timestamp)] Deployment failed: container did not remain running"
  exit 4
fi

# verify host port bound (best-effort)
HOST_PORT="${PORT_MAP%%:*}"
if command -v ss >/dev/null 2>&1; then
  if ss -ltnp | grep -q ":${HOST_PORT} "; then
    echo "[$(timestamp)] Host port ${HOST_PORT} is listening (OK)."
  else
    echo "[$(timestamp)] Warning: host port ${HOST_PORT} does not appear to be listening. Check container and firewall/security group."
  fi
elif command -v netstat >/dev/null 2>&1; then
  if netstat -ltnp | grep -q ":${HOST_PORT} "; then
    echo "[$(timestamp)] Host port ${HOST_PORT} is listening (OK)."
  else
    echo "[$(timestamp)] Warning: host port ${HOST_PORT} does not appear to be listening. Check container and firewall/security group."
  fi
else
  echo "[$(timestamp)] Note: cannot verify host port because neither ss nor netstat is available."
fi

echo "[$(timestamp)] Deployment finished. Container ${CONTAINER_NAME} is running and mapped to host port ${HOST_PORT}."
echo "[$(timestamp)] Deploy script completed successfully."
