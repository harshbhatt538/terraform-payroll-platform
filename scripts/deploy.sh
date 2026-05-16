#!/bin/bash
set -e

# ─────────────────────────────────────────
# Deployment script — runs on EC2 via SSM
# Called by GitHub Actions after image push
# ─────────────────────────────────────────

SERVICE_NAME=$1
APP_ENV=$2
IMAGE_TAG=$3

if [ -z "$SERVICE_NAME" ] || [ -z "$APP_ENV" ] || [ -z "$IMAGE_TAG" ]; then
  echo "Usage: deploy.sh <service_name> <environment> <image_tag>"
  exit 1
fi

echo "Deploying $SERVICE_NAME ($APP_ENV) with tag $IMAGE_TAG"

# Pull the latest image from ECR-less registry
# We use GitHub Container Registry (free, no paid ECR needed)
IMAGE="ghcr.io/$GITHUB_REPOSITORY/$SERVICE_NAME:$IMAGE_TAG"

# Stop existing container if running
docker stop "$SERVICE_NAME" 2>/dev/null || true
docker rm "$SERVICE_NAME" 2>/dev/null || true

# Pull new image
docker pull "$IMAGE"

# Run new container
docker run -d \
  --name "$SERVICE_NAME" \
  --restart unless-stopped \
  -p 8080:8080 \
  -e SERVICE_NAME="$SERVICE_NAME" \
  -e APP_ENV="$APP_ENV" \
  "$IMAGE"

echo "Deployment complete — $SERVICE_NAME is running"

# Basic health check
sleep 3
curl -f http://localhost:8080/health || {
  echo "Health check failed — rolling back"
  docker stop "$SERVICE_NAME"
  exit 1
}