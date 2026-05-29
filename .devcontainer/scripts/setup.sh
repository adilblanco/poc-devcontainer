#!/usr/bin/env bash
# setup.sh — runs at postStartCommand (each container start).
# Creates the Kind cluster if it doesn't exist yet, then writes the kubeconfig.
set -euo pipefail

CLUSTER_NAME="local"

echo "==> Waiting for Docker Engine (DinD) to be ready"
until docker info &>/dev/null; do sleep 1; done

if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
  echo "==> Kind cluster '${CLUSTER_NAME}' already exists, skipping creation"
else
  echo "==> Creating Kind cluster '${CLUSTER_NAME}'"
  kind create cluster --name "${CLUSTER_NAME}" --wait 90s
fi

echo "==> Writing kubeconfig"
kind export kubeconfig --name "${CLUSTER_NAME}"

echo "==> Configuring Astronomer CLI for local development"
# Disable telemetry and set the project directory to /workspaces (non-interactive).
astro config set -g disable_telemetry true 2>/dev/null || true

echo "==> setup.sh done"
