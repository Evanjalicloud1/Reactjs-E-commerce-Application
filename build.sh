#!/usr/bin/env bash
set -euo pipefail

# Usage: ./build.sh <branch> <tag>
# Example: ./build.sh dev latest
BRANCH=${1:-dev}
TAG=${2:-latest}

# Your Docker Hub username
DOCKERHUB_USER="evanjali1468"

DEV_REPO="${DOCKERHUB_USER}/dev"
PROD_REPO="${DOCKERHUB_USER}/prod"

if [ "$BRANCH" = "main" ] || [ "$BRANCH" = "master" ]; then
  REPO="$PROD_REPO"
else
  REPO="$DEV_REPO"
fi

IMAGE="${REPO}:${TAG}"

echo "🚀 Building Docker image ${IMAGE} ..."
docker build -t "${IMAGE}" .

echo "🔑 Logging into Docker Hub..."
docker login -u "${DOCKERHUB_USER}"

echo "📤 Pushing ${IMAGE} ..."
docker push "${IMAGE}"

echo "✅ Done: ${IMAGE}"
