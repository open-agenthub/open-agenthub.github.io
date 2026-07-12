#!/bin/sh
# Open AgentHub — all-in-one quickstart (Linux + macOS)
#
#   curl -fsSL https://open-agenthub.github.io/install.sh | sh
#
# Linux:  installs k3s (single-node Kubernetes) if no cluster is reachable.
# macOS:  uses Docker Desktop and creates a k3d cluster (no Homebrew needed).
# Then installs Helm if missing and deploys Open AgentHub from the official
# Helm repository. Recommended: 4 vCPU / 6 GB RAM (good for up to ~6 users).
set -eu

HELM_REPO="https://open-agenthub.github.io/open-agenthub"
NAMESPACE="agenthub"

say()  { printf '\033[1;33m[open-agenthub]\033[0m %s\n' "$*"; }
fail() { printf '\033[1;31m[open-agenthub] ERROR:\033[0m %s\n' "$*" >&2; exit 1; }

command -v curl >/dev/null 2>&1 || fail "curl is required"

OS="$(uname -s)"
ARCH="$(uname -m)"
case "$ARCH" in
  x86_64) ARCH=amd64 ;;
  aarch64 | arm64) ARCH=arm64 ;;
esac

SUDO=""
if [ "$(id -u)" -ne 0 ]; then
  command -v sudo >/dev/null 2>&1 || fail "please run as root or install sudo"
  SUDO="sudo"
fi

KUBECTL="kubectl"

# --- Kubernetes ----------------------------------------------------------------
if command -v kubectl >/dev/null 2>&1 && kubectl cluster-info >/dev/null 2>&1; then
  say "existing Kubernetes cluster detected — using it"
elif [ "$OS" = "Darwin" ]; then
  # macOS: single-node cluster in Docker via k3d (k3s does not run natively on macOS).
  docker info >/dev/null 2>&1 || fail "Docker is not running — install/start Docker Desktop first: https://www.docker.com/products/docker-desktop/"
  if ! command -v kubectl >/dev/null 2>&1; then
    say "installing kubectl"
    KVER="$(curl -Ls https://dl.k8s.io/release/stable.txt)"
    curl -fsSLo /tmp/kubectl "https://dl.k8s.io/release/${KVER}/bin/darwin/${ARCH}/kubectl"
    $SUDO install -m 0755 /tmp/kubectl /usr/local/bin/kubectl && rm -f /tmp/kubectl
  fi
  if ! command -v k3d >/dev/null 2>&1; then
    say "installing k3d"
    curl -fsSL https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
  fi
  if ! k3d cluster list 2>/dev/null | grep -q '^agenthub '; then
    say "creating k3d cluster \"agenthub\" (inside Docker Desktop)"
    k3d cluster create agenthub --wait
  else
    say "k3d cluster \"agenthub\" already exists — using it"
  fi
elif [ "$OS" = "Linux" ]; then
  say "no cluster found — installing k3s (single node)"
  curl -fsSL https://get.k3s.io | $SUDO sh -s - --write-kubeconfig-mode 644
  KUBECTL="$SUDO k3s kubectl"
  export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
  say "waiting for the node to become ready …"
  i=0
  until $KUBECTL get nodes 2>/dev/null | grep -q ' Ready'; do
    i=$((i+1)); [ $i -gt 60 ] && fail "k3s node did not become ready"
    sleep 2
  done
  say "k3s is ready"
else
  fail "unsupported OS: $OS (Windows: iwr -useb https://open-agenthub.github.io/install.ps1 | iex)"
fi

# --- Helm ----------------------------------------------------------------------
if ! command -v helm >/dev/null 2>&1; then
  say "installing Helm"
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | $SUDO bash
fi

# --- Deploy Open AgentHub ------------------------------------------------------
say "adding Helm repository"
helm repo add agenthub "$HELM_REPO" >/dev/null
helm repo update agenthub >/dev/null

# Generated once; kept in the cluster secret afterwards.
PGPW="$(head -c 24 /dev/urandom | od -An -tx1 | tr -d ' \n')"

say "deploying Open AgentHub"
helm upgrade --install agenthub agenthub/open-agenthub \
  -n "$NAMESPACE" --create-namespace \
  --set postgres.password="$PGPW" \
  --set postgres.persistence=true \
  --wait --timeout 10m

say ""
say "done! Open AgentHub is running."
say ""
say "next steps:"
say "  1. Reach the UI (no ingress configured yet):"
say "       kubectl -n $NAMESPACE port-forward svc/agenthub-frontend 8080:80 &"
say "       kubectl -n $NAMESPACE port-forward svc/agenthub-backend 8081:80 &"
say "     then open http://localhost:8080"
say "     For production, set ingress.host + TLS: https://github.com/open-agenthub/open-agenthub"
say "  2. Auth is DISABLED by default (dev mode). Enable your OIDC provider:"
say "       helm upgrade agenthub agenthub/open-agenthub -n $NAMESPACE --reuse-values \\"
say "         --set oidc.authority=https://<provider>/realms/<realm>"
say "  3. In the UI: store your credentials, start your first session."
