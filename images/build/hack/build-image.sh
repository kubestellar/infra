#!/usr/bin/env bash

set -euo pipefail

# Use "buildah" or "buildx" - default to buildah if docker is not available
if command -v docker &> /dev/null; then
  : "${BUILDER:=buildx}"
else
  : "${BUILDER:=buildah}"
fi
repository=ghcr.io/kubestellar/infra/build
architectures="amd64 arm64"
platforms="linux/amd64,linux/arm64"

# Optional mirror config for CI
if [ -n "${DOCKER_REGISTRY_MIRROR_ADDR:-}" ]; then
  mirror="$(echo "$DOCKER_REGISTRY_MIRROR_ADDR" | awk -F// '{print $NF}')"
  echo "Configuring registry mirror for docker.io ..."
  cat <<EOF > /etc/containers/registries.conf.d/mirror.conf
[[registry]]
prefix = "docker.io"
insecure = true
location = "$mirror"
EOF
fi

cd "$(dirname "$0")/../$1"
source ./env

image="$repository:${BUILD_IMAGE_TAG}"

# Download kindest image to embed (skip in DRY_RUN mode for presubmit validation)
if [ -z "${DRY_RUN:-}" ]; then
  echo "📦 Downloading kindest image to embed ..."
  if command -v docker &> /dev/null; then
    docker pull docker.io/${KINDEST_IMAGE}
    docker save ${KINDEST_IMAGE} -o kindest.tar
  elif command -v skopeo &> /dev/null; then
    # Use skopeo to download the image as a docker-archive tarball
    skopeo copy --all docker://docker.io/${KINDEST_IMAGE} docker-archive:kindest.tar:${KINDEST_IMAGE}
  else
    echo "⚠️ Neither docker nor skopeo available. Creating empty kindest.tar placeholder."
    touch kindest.tar
  fi
else
  echo "🛑 DRY_RUN is set; skipping kindest image download."
  # Create empty tarball for build validation
  touch kindest.tar
fi

if [ "$BUILDER" = "buildah" ]; then
  echo "🔧 Using buildah to build multi-arch images..."

  for arch in $architectures; do
    fullTag="$image-$arch"
    echo "Building $fullTag ..."
    buildah build-using-dockerfile \
      --file Dockerfile \
      --tag "$fullTag" \
      --arch "$arch" \
      --override-arch "$arch" \
      --build-arg "GO_VERSION=${GO_VERSION}" \
      --format docker \
      .
  done

  echo "📦 Creating buildah manifest $image ..."
  buildah manifest create "$image"
  for arch in $architectures; do
    buildah manifest add "$image" "$image-$arch"
  done

  if [ -z "${DRY_RUN:-}" ]; then
    # Support both old and new env var naming conventions
    GHCR_USER="${KUBESTELLAR_GHCR_USERNAME:-${GHCR_USERNAME:-}}"
    GHCR_PASS="${KUBESTELLAR_GHCR_PASSWORD:-${GHCR_TOKEN:-}}"

    echo "🔐 Logging into GHCR via buildah ..."
    buildah login --username "$GHCR_USER" --password "$GHCR_PASS" ghcr.io

    echo "🚀 Pushing manifest and images ..."
    buildah manifest push --all "$image" "docker://$image"
  else
    echo "🛑 DRY_RUN is set; skipping push."
  fi

elif [ "$BUILDER" = "buildx" ]; then
  echo "🔧 Using docker buildx to build and push $image for $platforms"

  if [ -z "${DRY_RUN:-}" ]; then
    # Support both old and new env var naming conventions
    GHCR_USER="${KUBESTELLAR_GHCR_USERNAME:-${GHCR_USERNAME:-}}"
    GHCR_PASS="${KUBESTELLAR_GHCR_PASSWORD:-${GHCR_TOKEN:-}}"
    echo "$GHCR_PASS" | docker login ghcr.io -u "$GHCR_USER" --password-stdin
    pushFlag="--push"
  else
    pushFlag="--load"
    echo "🛑 DRY_RUN is set; image will be loaded locally only."
  fi

  docker buildx build \
    --platform "$platforms" \
    --file Dockerfile \
    --build-arg "GO_VERSION=${GO_VERSION}" \
    --tag "$image" \
    --push \
    --progress=plain \
    $pushFlag \
    .

else
  echo "❌ Unsupported builder: $BUILDER"
  exit 1
fi

echo "✅ Done."
