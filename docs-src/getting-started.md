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

Keep the generated Postgres password — Postgres keeps the password it was initialised with,
so every later upgrade has to pass the same one.

::: tip Object storage is strongly recommended
Without S3-compatible object storage the hub runs, but sessions cannot be resumed in a fresh
pod, finished sessions keep no history, and uploaded files and artifacts disappear with the
agent pod. Point `s3.*` at a provider you already run, or let the chart deploy Garage
(`objectStorage.enabled=true` plus a one-time bootstrap — see the
[README](https://github.com/open-agenthub/open-agenthub#object-storage)). The quickstart
below sets it up automatically.
:::

## You don't have Kubernetes

The all-in-one quickstart sets up a single-node cluster and deploys Open AgentHub with
persistent Postgres **and** object storage. Recommended: 4 vCPU / 6 GB RAM, which
comfortably serves about six users.

Linux (installs k3s) and macOS (k3d in Docker Desktop):

```bash
curl -fsSL https://open-agenthub.github.io/install.sh | sh
```

Windows (k3d in Docker Desktop; Windows PowerShell 5.1 or PowerShell 7):

```powershell
iwr -useb https://open-agenthub.github.io/install.ps1 | iex
```

The scripts are safe to re-run — generated passwords and storage keys are kept — and never
deploy into whatever cluster your current kubectl context points at. To deploy into an
existing cluster instead, set `AGENTHUB_KUBE_CONTEXT=<context>` (Linux/macOS).
`AGENTHUB_OBJECT_STORAGE=0` skips object storage, which is not recommended.

## First steps

### 1. Open the UI

With an ingress, browse to `https://<your-host>`. Without one (the quickstart default),
forward the port and open `http://localhost:8080`:

```bash
kubectl -n agenthub port-forward svc/agenthub-frontend 8080:80
```

The quickstart prints this command with the right `--context`. The frontend proxies `/api`
and `/ws` to the backend, so this one port-forward is all you need.

### 2. Sign in

Without an OIDC provider, the chart generates a random API key into the Secret
`agenthub-api-key`. The UI asks for it once per browser session, and it acts as the admin user
`admin`. `helm status agenthub -n agenthub` prints the same command:

```bash
kubectl -n agenthub get secret agenthub-api-key -o jsonpath='{.data.api-key}' | base64 -d; echo
```

Scripts send it as `Authorization: Bearer <key>`. The backend refuses to start with no login
configured at all; `auth.insecureDevMode=true` turns the login off, for local development only.

Open AgentHub speaks standard OIDC: the frontend runs the Authorization Code Flow with
PKCE (public client, no secret), the backend validates the JWT access token against
`oidc.authority` / `oidc.audience`. The user's `preferred_username` claim is the tenant
key. Register the following in your provider:

- **Redirect URI:** `https://<host>/auth/callback`
- **Post-logout redirect URI:** `https://<host>`
- **Allowed web origins / CORS:** `https://<host>`

Register a public OIDC client with Authorization Code Flow and PKCE method `S256`.
Configure the provider to issue JWT access tokens for this application's audience and to
include a stable `preferred_username` claim. If it requires a dedicated API scope, add
that scope to `oidc.scope` alongside `openid profile email`. The browser also always requests
`offline_access` to renew sessions after idle periods; allow it and issue refresh tokens for
this public client. Providers must return JWT access tokens, publish discovery and signing keys,
and allow browser requests to their token endpoint. Support depends on these capabilities;
providers that return opaque access tokens need a compatible identity broker.

```bash
helm upgrade agenthub agenthub/open-agenthub -n agenthub --reset-then-reuse-values \
  --set oidc.authority=https://identity.example.com \
  --set oidc.clientId=agenthub \
  --set oidc.audience=agenthub
```

### Move the quickstart to team login

Team login is available in both editions. Each signed-in user owns their sessions.
Before sharing the instance with your team:

1. Give the instance a stable hostname, for example `hub.example.com`, with DNS pointing at
   your ingress and a trusted TLS certificate. Set `ingress.enabled=true`, `ingress.host`,
   `ingress.tlsSecretName` to your certificate Secret. Update
   `frontendOrigin` to `https://hub.example.com`. Keep the existing release name and namespace.
2. Register the HTTPS redirects and origin above at the issuer. Both the browser and backend
   must reach the issuer hostname and trust its TLS certificate; cluster-only DNS is insufficient.
3. Save these settings with the OIDC values in your values file, then run `helm upgrade agenthub
   agenthub/open-agenthub -n agenthub --reset-then-reuse-values -f team-values.yaml --wait --timeout 5m`.
   OIDC takes precedence over the quickstart API key. Sign in as a configured administrator
   (`ee.admins`) before sharing the URL with your team. Existing API-key-owned sessions keep
   their original owner; changing login does not migrate ownership.

`oidc.requireHttpsMetadata` defaults to `true`. Keep it enabled for team deployments.
For an isolated HTTP issuer in a local test only, set it to `false`; this changes backend
metadata retrieval, not browser mixed-content restrictions or TLS trust. The backend validates
issuer metadata and signing keys before serving traffic. If it cannot fetch them within 20
seconds, it exits with one startup error. Check `kubectl logs -n agenthub deployment/agenthub-backend`
for DNS, TLS and issuer configuration; correct the values and retry the upgrade.

If an interrupted upgrade leaves the release in `pending-upgrade`, stop the original upgrade
process first. Run `helm history agenthub -n agenthub`, identify the previous successful
revision, then `helm rollback agenthub <revision> -n agenthub --wait --timeout 5m`. Correct the
OIDC values before upgrading again. Do not delete release Secrets to bypass the lock.

Opaque access tokens are not supported. An identity broker can supply compatible JWT
access tokens when an upstream provider cannot. An ID token alone does not satisfy the
backend's access-token validation.


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

Complete the first provider login in an Interactive session using the **Terminal** interface.
See [Provider login](/provider-login) for agent-specific commands, stored accounts, and the
1.0.0-rc.1 Workspace workaround. To continue a conversation on your workstation, see
[Continue locally](/local-sessions); to control sessions from an external client, see [MCP](/mcp).

The home screen's **Shared with me** section lists direct, inherited and project-shared
sessions with owner, role and status; Viewer questions do not increase “Needs you”.

### 5. Connect an external MCP client (optional)

Prefer the built-in [HTTP MCP endpoint](/mcp) with browser sign-in. Configure HTTPS and
opt in with `mcp.enabled: true`, then open **Settings → Connect to AgentHub** for ready-to-paste
client setup. A local stdio process with a personal API token is the alternative when needed.

## Where configuration lives

Everything — host, TLS issuer, images, S3, OIDC, resource limits — is in
[`helm/open-agenthub/values.yaml`](https://github.com/open-agenthub/open-agenthub/blob/main/helm/open-agenthub/values.yaml).

S3-compatible object storage — recommended for every install — unlocks session resume,
history for finished sessions, persistent session files and artifact uploads.

Keep your environment-specific values in a file rather than a growing pile of `--set`
flags. It makes upgrades reproducible and sidesteps the `--reuse-values` trap entirely:

```bash
helm upgrade agenthub agenthub/open-agenthub -n agenthub -f my-values.yaml
```
