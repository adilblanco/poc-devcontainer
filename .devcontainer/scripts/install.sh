#!/usr/bin/env bash
# install.sh — runs once at onCreateCommand (image build phase).
# Installs Astronomer CLI; kubectl, Helm, and Minikube come from the devcontainer feature.
set -euo pipefail

ASTRO_VERSION="1.28.1"

echo "==> Installing Astronomer CLI v${ASTRO_VERSION}"
curl -fsSL "https://install.astronomer.io" | bash -s -- "v${ASTRO_VERSION}"

echo "==> install.sh done"
