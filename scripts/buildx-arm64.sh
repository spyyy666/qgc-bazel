#!/usr/bin/env bash
set -euo pipefail

# Build only the arm64 variant of the image on an x86_64 host using buildx + qemu.
# Produces a local image tag and optionally runs a basic smoke test (listing the binary).

REGION=${REGION:-asia-east1}
PROJECT_ID=${PROJECT_ID:-docker-ci2}
REPO_NAME=${REPO_NAME:-spy}
IMAGE_NAME=${IMAGE_NAME:-ec}
TAG=${TAG:-dev-arm64-local}
CONTEXT_DIR=$(cd "$(dirname "$0")/.." && pwd)

echo "[+] Ensuring buildx builder with qemu is available"
if ! docker buildx inspect multiarch-builder >/dev/null 2>&1; then
  docker buildx create --name multiarch-builder --use
fi
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes >/dev/null 2>&1 || true

echo "[+] Building arm64 image (this may take a while)"
docker buildx build \
  --platform linux/arm64 \
  -f "$CONTEXT_DIR/docker/Dockerfile.arm64" \
  -t ${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/${IMAGE_NAME}:${TAG} \
  --build-arg QGC_SKIP_APPIMAGE=1 \
  --load \
  "$CONTEXT_DIR"

echo "[+] Build complete. Image tag: ${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/${IMAGE_NAME}:${TAG}"
echo "[+] Smoke test: printing help/version (may fail harmlessly if GUI needs display)"
docker run --rm --platform linux/arm64 ${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/${IMAGE_NAME}:${TAG} --help || true

echo "[+] To push this single-arch image (arm64) run:"
echo "    docker push ${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/${IMAGE_NAME}:${TAG}"
