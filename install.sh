#!/bin/sh
# Open AgentHub — all-in-one quickstart (Linux + macOS)
#
#   curl -fsSL https://open-agenthub.github.io/install.sh | sh
#
# Linux:  installs k3s (single-node Kubernetes).
# macOS:  uses Docker Desktop and creates a k3d cluster (no Homebrew needed).
# Then installs Helm if missing and deploys Open AgentHub from the official
# Helm repository — including persistent object storage (Garage) for session
# resume, history and artifacts. Recommended: 4 vCPU / 6 GB RAM (good for up
# to ~6 users).
#
# Optional environment variables:
#   AGENTHUB_KUBE_CONTEXT=<ctx>  deploy into this existing kubectl context instead
#   AGENTHUB_OBJECT_STORAGE=0    skip the bundled object storage (not recommended)
#   AGENTHUB_CHART=<ref>         chart to install (default: agenthub/open-agenthub)
set -eu

HELM_REPO="https://open-agenthub.github.io/open-agenthub"
NAMESPACE="agenthub"
CHART="${AGENTHUB_CHART:-agenthub/open-agenthub}"
OBJECT_STORAGE="${AGENTHUB_OBJECT_STORAGE:-1}"
CTX="${AGENTHUB_KUBE_CONTEXT:-}"

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

hex_secret() { head -c "$1" /dev/urandom | od -An -tx1 | tr -d ' \n'; }
decode_base64() { printf '%s' "$1" | base64 -d 2>/dev/null || printf '%s' "$1" | base64 -D; }

# --- Kubernetes ----------------------------------------------------------------
# Every kubectl/helm call below pins --kube-context, so a cluster your current
# context happens to point at is never touched by accident.
if [ -n "$CTX" ]; then
  say "using kubectl context \"$CTX\" (AGENTHUB_KUBE_CONTEXT)"
elif [ "$OS" = "Linux" ] && command -v k3s >/dev/null 2>&1; then
  say "k3s already installed — using it"
  export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
  CTX=default
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
    k3d cluster start agenthub --wait >/dev/null 2>&1 || true
  fi
  CTX=k3d-agenthub
elif [ "$OS" = "Linux" ]; then
  if command -v kubectl >/dev/null 2>&1 && kubectl cluster-info >/dev/null 2>&1; then
    fail "kubectl already reaches a cluster (context \"$(kubectl config current-context)\"). Deploy into it explicitly with AGENTHUB_KUBE_CONTEXT=<context>, or use the Helm instructions in the README."
  fi
  say "installing k3s (single node)"
  curl -fsSL https://get.k3s.io | $SUDO sh -s - --write-kubeconfig-mode 644
  export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
  CTX=default
else
  fail "unsupported OS: $OS (Windows: iwr -useb https://open-agenthub.github.io/install.ps1 | iex)"
fi

KCTL="kubectl --context $CTX"
say "waiting for the cluster to become ready …"
i=0
until $KCTL get nodes 2>/dev/null | grep -q ' Ready'; do
  i=$((i+1)); [ $i -gt 60 ] && fail "cluster (context $CTX) did not become ready"
  sleep 2
done

# --- Helm ----------------------------------------------------------------------
if ! command -v helm >/dev/null 2>&1; then
  say "installing Helm"
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | $SUDO bash
fi

# --- Configuration ---------------------------------------------------------------
# Secrets are never regenerated on a re-run: Postgres keeps the password it was
# initialised with, and a new storage key would leave every stored object unreachable.
existing_secret() {
  enc="$($KCTL -n "$NAMESPACE" get secret "$1" -o "jsonpath={.data.$2}" 2>/dev/null || true)"
  [ -n "$enc" ] && decode_base64 "$enc" || true
}

PGPW="$(existing_secret postgres-secret password)"
[ -n "$PGPW" ] || PGPW="$(hex_secret 24)"

set -- --set-string "postgres.password=$PGPW" \
       --set postgres.persistence=true \
       --set ingress.enabled=false

if [ "$OBJECT_STORAGE" != "0" ]; then
  S3_ACCESS="$(existing_secret agenthub-secrets S3__AccessKey)"
  S3_SECRET="$(existing_secret agenthub-secrets S3__SecretKey)"
  RPC_SECRET="$(existing_secret garage-secrets rpc_secret)"
  ADMIN_TOKEN="$(existing_secret garage-secrets admin_token)"
  # Garage only accepts an access key id shaped like its own: GK plus 24 hex characters.
  [ -n "$S3_ACCESS" ] || S3_ACCESS="GK$(hex_secret 12)"
  [ -n "$S3_SECRET" ] || S3_SECRET="$(hex_secret 32)"
  [ -n "$RPC_SECRET" ] || RPC_SECRET="$(hex_secret 32)"
  [ -n "$ADMIN_TOKEN" ] || ADMIN_TOKEN="$(hex_secret 16)"
  set -- "$@" --set objectStorage.enabled=true \
    --set-string "objectStorage.accessKey=$S3_ACCESS" \
    --set-string "objectStorage.secretKey=$S3_SECRET" \
    --set-string "objectStorage.rpcSecret=$RPC_SECRET" \
    --set-string "objectStorage.adminToken=$ADMIN_TOKEN"
else
  say "WARNING: object storage disabled — sessions cannot be resumed and finished sessions keep no history."
fi

# --- Deploy Open AgentHub ------------------------------------------------------
if [ "$CHART" = "agenthub/open-agenthub" ]; then
  say "adding Helm repository"
  # --force-update re-downloads the index, so an unreachable repository fails here
  # instead of silently installing a stale chart from the local cache.
  helm repo add agenthub "$HELM_REPO" --force-update >/dev/null \
    || fail "fetching the Helm repository $HELM_REPO failed"
fi

say "deploying Open AgentHub ($CHART)"
helm --kube-context "$CTX" upgrade --install agenthub "$CHART" \
  -n "$NAMESPACE" --create-namespace "$@" \
  --wait --timeout 10m

# Garage creates nothing by itself: a fresh node has no layout, no bucket and no
# key. Each step is skipped when it is already done, so a re-run costs nothing.
if [ "$OBJECT_STORAGE" != "0" ]; then
  $KCTL -n "$NAMESPACE" rollout status statefulset/garage --timeout=180s
  garage() { $KCTL -n "$NAMESPACE" exec garage-0 -- /garage "$@"; }
  if ! garage bucket list 2>/dev/null | grep -qE '[[:space:]]agenthub[[:space:]]'; then
    say "initialising object storage"
    layout="$(garage layout show 2>/dev/null || true)"
    version="$(printf '%s' "$layout" | sed -n 's/.*Current cluster layout version: \([0-9]*\).*/\1/p' | tail -1)"
    if [ "${version:-0}" -lt 1 ]; then
      node_id="$(garage node id -q 2>/dev/null | tr -d '\r' | cut -d@ -f1)"
      [ -n "$node_id" ] || fail "could not read the Garage node id"
      garage layout assign -z dc1 -c 18GB "$node_id" >/dev/null
      garage layout apply --version "$(( ${version:-0} + 1 ))" >/dev/null
    fi
    garage bucket create agenthub >/dev/null
    garage key import --yes "$S3_ACCESS" "$S3_SECRET" -n agenthub-key >/dev/null
    garage bucket allow --read --write --owner agenthub --key agenthub-key >/dev/null
    # The backend checked the bucket at startup; restart it so it picks the storage up.
    $KCTL -n "$NAMESPACE" rollout restart deployment/agenthub-backend >/dev/null
    $KCTL -n "$NAMESPACE" rollout status deployment/agenthub-backend --timeout=180s
  fi
  say "object storage ready"
fi

KC_HINT="kubectl --context $CTX"
[ -n "${KUBECONFIG:-}" ] && KC_HINT="KUBECONFIG=$KUBECONFIG $KC_HINT"

say ""
say "done! Open AgentHub is running."
say ""
say "next steps:"
say "  1. Reach the UI (no ingress configured):"
say "       $KC_HINT -n $NAMESPACE port-forward svc/agenthub-frontend 8080:80"
say "     then open http://localhost:8080"
say "     For production, set ingress.host + TLS: https://github.com/open-agenthub/open-agenthub"
say "  2. Auth is DISABLED by default (dev mode). Enable your OIDC provider:"
say "       helm --kube-context $CTX upgrade agenthub $CHART -n $NAMESPACE --reuse-values \\"
say "         --set oidc.authority=https://<provider>/realms/<realm>"
say "  3. In the UI: store your credentials, start your first session."
