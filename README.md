# poc-devcontainer

Local Airflow development environment using DevContainer with Docker-in-Docker (DinD),
Minikube, and Astronomer CLI.

## Architecture

```
Mac (ARM / M-series)
└── DevContainer (DinD)
    └── Docker Engine
        ├── Minikube cluster (192.168.49.0/24)
        │   └── KubernetesPodOperator pods run here
        └── Airflow via astro dev start (docker-compose)
            ├── webserver  → http://localhost:8080
            ├── scheduler
            ├── triggerer
            └── postgres
```

## Prerequisites

- Docker Desktop or Rancher Desktop
- VS Code with Dev Containers extension

## Getting started

### 1. Open the DevContainer

`Ctrl+Shift+P` → **Dev Containers: Rebuild and Reopen in Container**

The build automatically:
- Installs Astronomer CLI v1.28.1
- Starts Minikube (driver: docker)
- Generates `include/.kube/config` pointing to Minikube API

### 2. Install Python dependencies for DAG development

Install Airflow packages system-wide in the DevContainer so that VS Code resolves
imports in DAGs without errors (e.g. `from airflow.providers.cncf.kubernetes...`).
No virtualenv needed — the DevContainer is already an isolated environment.
Use `--no-deps` to avoid installing the full dependency tree.

```bash
use-dind
pip install apache-airflow-providers-cncf-kubernetes --no-deps
```

Then point VS Code to the system interpreter:
`Ctrl+Shift+P` → **Python: Select Interpreter** → `/usr/bin/python3`

### 3. Start Airflow

```bash
use-dind
astro dev start
```

### 4. Connect Airflow to the Minikube network

Required once after each `astro dev start` so that `KubernetesPodOperator`
can reach the Minikube API at `192.168.49.2:8443`.

```bash
use-dind
for c in $(docker ps --format '{{.Names}}' | grep "$(basename $(pwd))"); do
  docker network connect minikube $c 2>/dev/null || true
done
```

### 5. Open Airflow UI

http://localhost:8080 — login: `admin` / `admin`

## Docker context aliases

Two Docker daemons coexist in the DevContainer:

| Alias | Docker daemon | Use for |
|---|---|---|
| `use-dind` | DinD (default) | `astro` CLI, docker-compose |
| `use-minikube` | Minikube | Building images for KubernetesPodOperator |

```bash
# Build an image directly into Minikube (no transfer needed)
use-minikube
docker build -t my-image:1.0 .

# Return to DinD for Astro CLI
use-dind
astro dev restart
```

## Rebuild DevContainer

Always stop Airflow before rebuilding — Airflow containers stay attached to
the `minikube` Docker network and block Minikube from restarting.

```bash
use-dind
astro dev stop
# Ctrl+Shift+P → Dev Containers: Rebuild Container
```

> If you forget, `setup.sh` runs `astro dev stop` automatically at rebuild.

## Project structure

```
.devcontainer/
├── devcontainer.json
└── scripts/
    ├── install.sh   # Astronomer CLI installation (onCreateCommand)
    └── setup.sh     # Minikube start + kubeconfig generation (postStartCommand)
dags/                # Airflow DAGs
include/
└── .kube/
    └── config       # Kubeconfig for KubernetesPodOperator (auto-generated)
requirements.txt     # Airflow Python dependencies (applied via astro dev restart)
```
