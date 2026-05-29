#!/usr/bin/env bash
# setup.sh — runs at postStartCommand (each container start).
# Starts the Minikube cluster and configures the environment for Airflow.
set -euo pipefail

echo "==> Waiting for Docker Engine (DinD) to be ready"
until docker info &>/dev/null; do sleep 1; done

echo "==> Stopping Airflow if running (frees the minikube network before cluster start)"
astro dev stop 2>/dev/null || true

echo "==> Starting Minikube cluster (driver: docker)"
# --driver=docker runs Minikube inside the DinD Docker Engine.
# --embed-certs writes certs inline in kubeconfig (no external cert files needed).
if minikube status --profile minikube &>/dev/null; then
  echo "    Minikube already running, skipping start"
else
  # Delete any stale Minikube container left over from a previous DevContainer
  # build — it would cause an 'IP already in use' conflict on minikube start.
  minikube start --driver=docker --embed-certs --force
fi

echo "==> Writing kubeconfig for Airflow containers"
mkdir -p /workspaces/poc-devcontainer/include/.kube
# Use minikube IP directly — reachable from Airflow containers once connected
# to the same Docker network. The hostname approach requires extra DNS setup.
MINIKUBE_IP=$(minikube ip)
kubectl config view --flatten > /workspaces/poc-devcontainer/include/.kube/config
sed -i "s|server: https://[0-9.]*:[0-9]*|server: https://${MINIKUBE_IP}:8443|g" \
  /workspaces/poc-devcontainer/include/.kube/config
echo "    Minikube API server: https://${MINIKUBE_IP}:8443"

echo "==> Registering Docker context aliases in ~/.bashrc"
# Two separate Docker daemons coexist:
#   - DinD (default, DOCKER_HOST unset): used by Astro CLI
#   - Minikube docker engine: used when building images for KubernetesPodOperator
# Switching is explicit to avoid TLS conflicts with Astro CLI.
cat >> /root/.bashrc << 'EOF'

# Switch Docker CLI to Minikube daemon (images become available in the cluster).
alias use-minikube='eval $(minikube docker-env)'
# Switch back to the DinD daemon (required for Astro CLI).
alias use-dind='unset DOCKER_HOST DOCKER_TLS_VERIFY DOCKER_CERT_PATH MINIKUBE_ACTIVE_DOCKERD'
EOF

echo "==> Configuring Astronomer CLI for local development"
astro config set -g disable_telemetry true 2>/dev/null || true

echo "==> setup.sh done"
