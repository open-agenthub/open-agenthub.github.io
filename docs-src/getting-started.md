# Install

## You have a Kubernetes cluster

Prebuilt images come from `ghcr.io/open-agenthub/open-agenthub/*`, the chart from the
project's Helm repository:

```bash
helm repo add agenthub https://open-agenthub.github.io/open-agenthub
helm install agenthub agenthub/open-agenthub -n agenthub --create-namespace \
  --set postgres.password=$(openssl rand -hex 16) \
  --set ingress.host=hub.your-org.example
```

## You don't have Kubernetes

The all-in-one quickstart installs k3s (single node) plus Open AgentHub on a Linux host.
Recommended: 4 vCPU / 6 GB RAM, which comfortably serves about six users.

```bash
curl -fsSL https://open-agenthub.github.io/install.sh | sh
```

On Windows, with Docker Desktop and k3d:

```powershell
iwr -useb https://open-agenthub.github.io/install.ps1 | iex
```

## First steps

### 1. Open the UI

With an ingress, browse to `https://<your-host>`. Without one, forward the port:

```bash
kubectl -n agenthub port-forward svc/agenthub-frontend 8080:80
```

### 2. Turn on authentication

Authentication is **disabled by default**. That is fine for a first look on your laptop,
and wrong for anything other people can reach.

```bash
helm upgrade agenthub agenthub/open-agenthub -n agenthub --reset-then-reuse-values \
  --set oidc.authority=<issuer-url> \
  --set oidc.clientId=<client-id> \
  --set oidc.audience=<expected-audience>
```

The redirect URI to register with your identity provider is `https://<your-host>/auth/callback`.
Any standard OIDC provider works — Keycloak, Entra ID, Google.

::: warning Upgrading an existing release
Note the `--reset-then-reuse-values` above rather than the more familiar `--reuse-values`.
The difference matters and it will eventually break an upgrade for you — see
[Upgrading](/upgrading).
:::

### 3. Store your credentials

Under **Settings → Credentials**: an SSH key or a GitHub/GitLab token for repository
access, plus an Anthropic, OpenAI, or Cursor API key if you bill by API key. These fields
are write-only — status responses only ever tell you whether a value is stored, never what
it is.

For repository access you can skip the manual token entirely and connect an account over
OAuth instead; see [Git integrations](/git).

### 4. Start a session

Pick an agent (Claude, Codex, Cursor, or OpenClaw), the billing mode (subscription or API
key), and a session mode:

| Mode | What it does |
| --- | --- |
| Interactive | You drive it in the terminal or the chat pane. |
| Autonomous | Runs a prompt to completion under a policy allowlist. |
| Scheduled | Creates a CronJob that starts the task on a schedule. |

An interactive subscription session can complete the provider login in its own terminal:
Codex uses `codex login --device-auth`, Cursor uses `agent login`, and OpenClaw uses
`openclaw models auth add`.

## Where configuration lives

Everything — host, TLS issuer, images, S3, OIDC, resource limits — is in
[`helm/open-agenthub/values.yaml`](https://github.com/open-agenthub/open-agenthub/blob/main/helm/open-agenthub/values.yaml).

Optional S3/MinIO credentials unlock session resume, history for finished sessions, and
artifact uploads.

Keep your environment-specific values in a file rather than a growing pile of `--set`
flags. It makes upgrades reproducible and sidesteps the `--reuse-values` trap entirely:

```bash
helm upgrade agenthub agenthub/open-agenthub -n agenthub -f my-values.yaml
```
