#!/usr/bin/env bash
# Smoke test for an Open AgentHub installed by install.sh / install.ps1.
#
#   install-smoke.sh <kube-context>
#
# Checks that every pod becomes ready, that the UI and API answer through a single
# frontend port-forward, and that the bundled object storage accepts a real S3
# write/read/delete with the hub's own credentials.
set -euo pipefail

CTX="${1:?usage: install-smoke.sh <kube-context>}"
NS=agenthub
K=(kubectl --context "$CTX" -n "$NS")

echo "::group::pods"
"${K[@]}" rollout status deployment/agenthub-backend --timeout=300s
"${K[@]}" rollout status deployment/agenthub-frontend --timeout=300s
"${K[@]}" rollout status statefulset/postgres --timeout=300s
"${K[@]}" rollout status statefulset/garage --timeout=300s
"${K[@]}" get pods,pvc
echo "::endgroup::"

echo "::group::http"
"${K[@]}" port-forward svc/agenthub-frontend 18080:80 >/tmp/port-forward.log 2>&1 &
pf=$!
trap 'kill $pf 2>/dev/null || true' EXIT
for _ in $(seq 1 30); do curl -fs -o /dev/null http://localhost:18080/ && break; sleep 1; done
for path in / /api/config /api/sessions; do
  code="$(curl -s -o /dev/null -w '%{http_code}' "http://localhost:18080$path")"
  echo "$path -> $code"
  [ "$code" = 200 ] || { echo "::error::$path answered $code"; exit 1; }
done
echo "::endgroup::"

echo "::group::object storage"
secret() { "${K[@]}" get secret agenthub-secrets -o "jsonpath={.data.$1}" | base64 -d; }
"${K[@]}" run s3-smoke --rm -i --restart=Never --quiet --image=amazon/aws-cli:2.17.0 \
  --env "AWS_ACCESS_KEY_ID=$(secret S3__AccessKey)" \
  --env "AWS_SECRET_ACCESS_KEY=$(secret S3__SecretKey)" \
  --env AWS_DEFAULT_REGION=us-east-1 \
  --command -- sh -ec '
    s3="aws --endpoint-url http://garage:3900 s3"
    echo ok > /tmp/probe
    $s3 cp /tmp/probe s3://agenthub/install-smoke.txt
    $s3 cp s3://agenthub/install-smoke.txt /tmp/back
    cmp /tmp/probe /tmp/back
    $s3 rm s3://agenthub/install-smoke.txt
    echo "s3 round trip ok"'
echo "::endgroup::"

echo "smoke test passed"
