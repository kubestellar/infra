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
  docker pull docker.io/${KINDEST_IMAGE}
  docker save ${KINDEST_IMAGE} -o kindest.tar
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
    echo "🔐 Logging into GHCR via buildah ..."
    buildah login --username "$KUBESTELLAR_GHCR_USERNAME" --password "$KUBESTELLAR_GHCR_PASSWORD" ghcr.io

    echo "🚀 Pushing manifest and images ..."
    buildah manifest push --all "$image" "docker://$image"
  else
    echo "🛑 DRY_RUN is set; skipping push."
  fi

elif [ "$BUILDER" = "buildx" ]; then
  echo "🔧 Using docker buildx to build and push $image for $platforms"

  if [ -z "${DRY_RUN:-}" ]; then
    echo "$KUBESTELLAR_GHCR_PASSWORD" | docker login ghcr.io -u "$KUBESTELLAR_GHCR_USERNAME" --password-stdin
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
