#!/usr/bin/env bash

# This script runs as the post-infra-deploy-prow-cluster postsubmit whenever
# clusters/prow/ changes on main. It applies the Prow component manifests in
# clusters/prow/manifests/prow/ to the Prow cluster.
#
# It runs in-cluster as the test-pods/prow-deployer ServiceAccount (see
# clusters/prow/manifests/deployer/), which can manage only those objects and
# cannot read Secrets. Secrets are managed out of band and are only referenced
# by name in the manifests.
#
# Prow's own configuration (prow/config.yaml, prow/plugins.yaml and the job
# configs) is not applied here: the config_updater plugin syncs it.
#
# Cluster add-ons (ingress-nginx, cert-manager, the ProwJob CRD) are not
# managed by this script.

set -euo pipefail

cd "$(dirname "$0")/../.."
source hack/settings.sh
source hack/lib.sh

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

cp manifests/prow/*.yaml "$workdir/"
sed_settings "$workdir/*.yaml"

if grep -l '__[A-Z_]*__' "$workdir"/*.yaml; then
  echo "Unrendered placeholders found in the files above, aborting."
  exit 1
fi

echo "Changes that will be applied:"
# kubectl diff exits 1 when there are differences, >1 on errors
rc=0
kubectl diff --filename "$workdir/" || rc=$?
if [ "$rc" -gt 1 ]; then
  echo "kubectl diff failed (exit code $rc), aborting."
  exit "$rc"
fi
if [ "$rc" -eq 0 ]; then
  echo "(no changes)"
fi

echo "Applying Prow manifests..."
kubectl apply --filename "$workdir/"

echo "Done :-)"
