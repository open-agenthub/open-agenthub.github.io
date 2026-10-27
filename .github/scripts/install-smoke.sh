#!/usr/bin/env bash
# Checks that install.sh left a working Open AgentHub behind.
#
# `helm --wait` already blocks until the pods report ready, so repeating that would assert
# almost nothing. What it cannot tell us is whether the thing actually serves: a chart change
# that renames a service, moves a port or breaks the backend's database wiring leaves every
# pod healthy and the product unusable. So the last two checks talk to it over the network.
#
# Called as: install-smoke.sh <kube-context>
# The open-agenthub repository runs this against the chart from its own checkout, which is how
# a chart change gets caught before it reaches the published quickstart.
set -euo pipefail

CTX="${1:?usage: install-smoke.sh <kube-context>}"
NS="${AGENTHUB_NAMESPACE:-agenthub}"
RELEASE="${AGENTHUB_RELEASE:-agenthub}"
KCTL="kubectl --context $CTX -n $NS"

say() { printf '  [smoke] %s\n' "$*"; }
fail() { printf '  [smoke] FAILED: %s\n' "$*" >&2; exit 1; }

# --- The release itself ---------------------------------------------------------
status="$(helm --kube-context "$CTX" -n "$NS" status "$RELEASE" -o json 2>/dev/null \
  | sed -n 's/.*"status":"\([a-z-]*\)".*/\1/p' | head -1)"
[ "$status" = "deployed" ] || fail "helm release $RELEASE is \"${status:-missing}\", not deployed"
say "helm release $RELEASE is deployed"

# --- Workloads ------------------------------------------------------------------
# By name would mean editing this file whenever the chart grows a component, and a component
# that silently stopped being deployed would still pass. Everything the release created has
# to be ready instead.
deployments="$($KCTL get deploy -o name 2>/dev/null || true)"
[ -n "$deployments" ] || fail "no deployments in namespace $NS"
$KCTL wait --for=condition=Available --timeout=10m $deployments \
  || fail "not every deployment became available"
say "deployments available: $(echo "$deployments" | tr '\n' ' ')"

for sts in $($KCTL get statefulset -o name 2>/dev/null || true); do
  $KCTL rollout status "$sts" --timeout=5m || fail "$sts did not become ready"
done

# --- It actually answers ---------------------------------------------------------
# From inside the cluster rather than through a port-forward: a forward that dies mid-request
# fails the run for a reason that has nothing to do with the chart.
#
# Retried rather than asked once. "Available" on a Deployment only means the pod is running,
# and the frontend carries no readiness probe — nginx may not have bound its port yet when the
# first request arrives. A smoke test that races is worse than none, because the failure looks
# like a broken chart.
probe() {
  local name="$1" url="$2" expect="$3"
  local code attempt=0 out=''
  while [ $attempt -lt 20 ]; do
    attempt=$((attempt + 1))
    out="$($KCTL run "smoke-$name-$attempt-$$" --rm -i --restart=Never --quiet \
      --image=curlimages/curl:8.11.1 --command -- \
      curl -s -o /dev/null -w '%{http_code}' --max-time 20 "$url" 2>&1 || true)"
    code="$(printf '%s' "$out" | tr -d '\r\n' | tail -c 3)"
    [ "$code" = "$expect" ] && { say "$name answered HTTP $code (attempt $attempt)"; return 0; }
    sleep 5
  done
  # The last response in full, not just the parsed code: when this fires it is usually because
  # kubectl could not run the probe at all, and the bare code hides that.
  printf '  [smoke] last probe output: %s\n' "$out" >&2
  $KCTL get endpoints -o wide >&2 2>/dev/null || true
  fail "$name never answered HTTP $expect ($url)"
}

# Auth is disabled in the quickstart's dev mode, so the API answers an unauthenticated read.
# If that ever changes this expectation has to move with it — a 401 here means the install
# produced something a first-time user cannot click through, which is worth failing on.
probe backend "http://$RELEASE-backend.$NS.svc.cluster.local/api/sessions" 200
probe frontend "http://$RELEASE-frontend.$NS.svc.cluster.local/" 200

say "all checks passed"
