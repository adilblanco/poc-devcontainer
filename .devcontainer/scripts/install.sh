#!/usr/bin/env bash
# install.sh — runs once at onCreateCommand (image build phase).
# Installs Kind and Astronomer CLI; kubectl and Helm come from the devcontainer feature.
set -euo pipefail

ASTRO_VERSION="1.28.1"
KIND_VERSION="v0.23.0"   # last stable release; supports k8s 1.29–1.32

echo "==> Installing Kind ${KIND_VERSION}"
curl -fsSL "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-arm64" \
  -o /usr/local/bin/kind
chmod +x /usr/local/bin/kind

echo "==> Installing Astronomer CLI v${ASTRO_VERSION}"
curl -fsSL "https://install.astronomer.io" | bash -s -- "v${ASTRO_VERSION}"

echo "==> install.sh done"
