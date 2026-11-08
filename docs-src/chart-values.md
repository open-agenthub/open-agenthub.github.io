# Chart values for operators

The Helm chart has many values; this page covers the ones an operator of Open AgentHub 1.14.1
most often needs to set or change. Defaults are those of `helm/open-agenthub/values.yaml` at
v1.14.1. For everything else, read the
[values file](https://github.com/open-agenthub/open-agenthub/blob/main/helm/open-agenthub/values.yaml)
itself; its comments explain each key.

**Edition:** Community (Enterprise-only values are marked) · **Who:** operator

::: tip Keep a values file
Pass your settings with `-f my-values.yaml` rather than `--reuse-values`, so new defaults
arrive with each upgrade. See [Upgrading](/upgrading).
:::

## Images

| Value | Default | What it does, when to change it |
| --- | --- | --- |
| `image.registry` | `ghcr.io/open-agenthub/open-agenthub` | Base path of every component image. Change it for a mirror or your own build. |
| `image.tag` | empty (= the chart's `appVersion`) | Selects the backend, frontend, browser, renderer and all five agent runtimes at once, so they always move together. Empty installs exactly the release the chart belongs to, and a chart upgrade moves every image. Set it only to deviate on purpose; quote a commit-SHA tag, or YAML may read it as a number. |
| `agent.pullPolicy` | `IfNotPresent` | Use `Always` (with `image.pullPolicy: Always`) only if you set a moving tag such as `latest`, so nodes do not keep a stale image. |
| `agent.autoUpdateRuntimeImages` | `false` | Replaces an outdated runtime image in a running session automatically, but only when the session confirms it is idle. Interactive sessions only; autonomous runs are never restarted, and object storage is required. Sessions can override it under **Edit session → Automatic runtime image updates**. Otherwise the owner uses **Update now**. |

## Backend and database

| Value | Default | What it does, when to change it |
| --- | --- | --- |
| `backend.replicas` | `2` | Backend pods. Telegram or Signal ([Chat](/chat)) need exactly `1`; the chart refuses to render otherwise. |
| `backend.database.maxPoolSize` | `20` | Shared Postgres pool per replica. Overrides a `Maximum Pool Size` in `externalDatabase.connectionString`. |
| `backend.database.lockPoolSize` | `10` | Separate pool for connections that hold a database lock (integrated browser starts, token refreshes, sweeps, role changes). |
| `externalDatabase.connectionString` | empty | Your own Postgres, used when `postgres.enabled=false`, e.g. `Host=db.your-org.example;Database=agenthub;Username=agenthub;Password=...`. |
| `postgres.enabled` | `true` | Runs the bundled Postgres. Requires `postgres.password`. |
| `postgres.persistence` / `postgres.storage` | `true` / `5Gi` | PVC for the bundled database. `persistence: false` uses an emptyDir and loses data on restart: testing only. |
| `postgres.appArmorUnconfined` | `false` | Last resort, see below. |

### Shared protection keys

**Community and Enterprise · operator.** The release containing
[issue #458](https://github.com/open-agenthub/open-agenthub/issues/458) stores the backend's
Data Protection key ring in Postgres. Replicas and replacement pods use the same keys for
stored MCP secrets, webhook secrets, gateway tokens and cleanup previews.

| Value | Default | What it does |
| --- | --- | --- |
| `dataProtection.existingSecret` | empty | Empty: Helm generates and retains `agenthub-data-protection`. Set a Secret name to supply your own RSA PEM certificate (`tls.crt`) and matching private key (`tls.key`), at least 2048 bits. The Secret must be in the backend namespace. |

Normal `helm install` / `helm upgrade` reuses the generated Secret. It is deliberately
retained on uninstall: keep it if you intend to restore or reconnect the same database.
**Back up Postgres and this Secret together.** Losing or replacing the wrapping identity
prevents the backend from reading the existing ring; startup stops with an error.

For a declarative deployment or offline `helm template`, create and manage a stable Secret
first, because an offline render cannot look up an existing generated Secret:

```yaml
dataProtection:
  existingSecret: my-data-protection
```

Create the Secret from your certificate and private-key files:

```sh
kubectl -n agenthub create secret tls my-data-protection --cert=certificate.pem --key=private-key.pem
```

This certificate wraps stored keys; it does not need to be your ingress TLS certificate.
Restrict access to the private key. Restart backend pods after changing Secret input. Do not
replace the certificate as a routine rotation: historical ring entries and database backups
still need the old private key. Overlapping decryption certificates require operator-provided
backend configuration; see the
[rotation decision](https://github.com/open-agenthub/open-agenthub/blob/main/docs/data-protection.md).

Outside the chart, every backend requires the same `DataProtection__CertificatePem` and
`DataProtection__PrivateKeyPem` environment values. No key directory in HOME is needed.
See [upgrade recovery](/upgrading#shared-protection-keys-and-secret-recovery).

### The connection budget

Each replica uses at most `maxPoolSize + lockPoolSize + 2` connections: one for change
notifications, and one for the schema migration lock during startup. With the defaults that is 32 per
replica, **64 for two replicas, and briefly 96** while a rolling update runs one extra (surge) pod.
In practice a replica holds about 3 connections after startup and about 20 under load, but the
database has to allow for the ceiling.

Many managed Postgres plans allow only `max_connections=100`, a few of them reserved by the
provider. Backups, migrations and other clients come on top. On such a plan, lower `maxPoolSize`
(say to 15) or raise `max_connections` **before** you add a replica.

`lockPoolSize` caps how many locked operations one replica can run at the same moment. A request
that finds the lock pool full waits up to 15 seconds, then fails.

### Bundled Postgres

The bundled database is meant for evaluation and small installs. Since 1.14.0 it is initialised in
an init container, which avoids a shutdown signal that some hosts' AppArmor profile denies. A
volume whose data directory already has a non-empty `PG_VERSION` file is left alone, so
existing databases are not initialised again.

On such a host, later operations that need the same signal can still fail: a manual `CHECKPOINT`
and crash recovery, and probably backups that request a checkpoint. **For production, use an
external database.** `postgres.appArmorUnconfined: true` runs the bundled Postgres pod without
AppArmor confinement. That weakens its security profile, so use it only as a last resort. The
decision record
[postgres-startup.md](https://github.com/open-agenthub/open-agenthub/blob/main/docs/postgres-startup.md)
explains the trade-off.

## Object storage and session egress

Object storage holds session state, scrollback, transcripts and files. Without it, sessions run,
but cannot be resumed and have no history.

| Value | Default | What it does, when to change it |
| --- | --- | --- |
| `objectStorage.enabled` | `false` | Deploys a single-node S3-compatible store in the cluster and wires `s3.*` to it. It needs a one-time bootstrap (layout, bucket, key); the README's object storage section has the commands. |
| `s3.serviceUrl` | empty | Your own S3-compatible endpoint, as the backend reaches it. Set values win over the bundled store. |
| `s3.publicUrl` | empty | Leave empty to stream browser uploads and downloads through the API. |
| `agent.storageEgress.cidrs` | `[]` | Destination networks for external storage reached **by DNS name on a port other than 80 or 443**. |
| `agent.extraEgressPorts` | `[]` | Extra TCP ports session pods may reach, to **any** destination. Ports 53, 80, 443 and 22 are always open. |
| `agent.trustedCaConfigMap` | empty | ConfigMap in the sessions namespace with a PEM bundle under `ca.crt`, for storage or other endpoints behind a private CA. Applies when a session pod starts; pause and resume running sessions to pick it up. |

Session pods talk to object storage directly. The chart opens the bundled store and an external
store at a literal IP address automatically. A Kubernetes network policy cannot match a DNS name,
so for `s3.serviceUrl: https://s3.your-org.example:9000` set `agent.storageEgress.cidrs` to the
endpoint's networks. If you cannot, `agent.extraEgressPorts: [9000]` opens that port to every
destination. `helm install` and `helm upgrade` print a warning when neither is set. Sessions that
cannot reach storage cannot save or restore their state.

## Sign-in and network trust

| Value | Default | What it does, when to change it |
| --- | --- | --- |
| `oidc.authority` | empty | Issuer URL of your OIDC provider. Empty means the API key below guards the instance. |
| `oidc.clientId` / `oidc.audience` | `agenthub` / `agenthub` | Client and expected `aud` claim. Empty audience skips that check. |
| `auth.apiKey.existingSecret` | empty | Empty: the chart generates the key into Secret `agenthub-api-key`. Set it for GitOps (`helm template`). |
| `auth.apiKey.owner` | empty | The user the key acts as, always an admin. |
| `auth.insecureDevMode` | `false` | No login at all. Local development only. |
| `backend.forwardedHeaders.knownProxies` | `127.0.0.1,::1` | Proxies whose `X-Forwarded-For` the backend trusts, for example to throttle wrong API keys per client. |
| `backend.forwardedHeaders.knownNetworks` | private ranges | Narrow both to your ingress controller's source range. |

The API key, rotation and GitOps setup are described in [Upgrading](/upgrading#installs-without-oidc-the-api-key).

## Sessions

| Value | Default | What it does, when to change it |
| --- | --- | --- |
| `agent.maxCpu` / `agent.maxMemory` | `2` / `4Gi` | Limit of every session that sets none. |
| `agent.cpuLimitCeiling` / `agent.memoryLimitCeiling` | empty | Highest limit a session may set for itself. Empty means `maxCpu` / `maxMemory`. Raise them to let single sessions use more. |
| `agent.minCpu` / `agent.minMemory` | `50m` / `256Mi` | Smallest request a session may ask for. A new session requests 500m CPU and 1Gi memory unless its owner changes that. |
| `maxRunningSessionsPerOwner` | `50` | Concurrent non-terminal sessions per user. More are refused with HTTP 429. |
| `agent.allowRootSessions` | `true` | Lets users run a session as root, to install tools. It needs Pod Security "baseline" on the sessions namespace; set `false` to allow "restricted". |
| `agent.allowCustomImage` | `true` | Lets users pick their own container image per session. |
| `spawnMcpEnabled` | `true` | The in-session sessions MCP: child sessions, messages between sessions. [Session tools](/session-tools) depend on it, and so do helper containers. |
| `telemetry.enabled` | `true` | Claude Code usage export for the [Usage page](/usage). |
| `telemetry.otlpEndpoint` | `""` | Empty sends metrics to the internal backend. A custom collector receives no session callback credential and does not feed AgentHub usage. |

## Features

| Value | Default | What it does, when to change it |
| --- | --- | --- |
| `browser.enabled` | `true` | The integrated browser ([Browser](/browser)). |
| `browser.previewPorts` | `[3000, 4173, 5173, 8000, 8080]` | Ports on the session's own pod the browser may open. `[]` disables it. See [Preview](/preview). |
| `mcp.enabled` | `false` | Remote MCP endpoint at `/mcp` for external clients. See [MCP](/mcp). |
| `mcp.publicUrl` | empty | External HTTPS origin of that endpoint. Empty means it is derived from `ingress.host`. |
| `sharing.userSuggestionsEnabled` | `true` | Enterprise. The share dialog suggests users after two typed characters. `false` allows only an exact username or email. |
| `ee.admins` | empty | Comma-separated usernames that are always admins. With OIDC, set at least one: nobody is an admin by default. See [Administration](/admin#designating-the-first-admin). |

## Licence report warning

`ee.license.reportWarningDays` controls how many days before the current signed licence token
expires the Admin license page warns (default `7`, range `0`–`365`). Zero warns at expiry.
It does not change entitlement validity or report frequency. See [renewal health](/admin#check-renewal-health).

## Backend private CA trust

`backend.trustedCaConfigMap` defaults to empty (runtime trust unchanged). Set it to an
existing ConfigMap in the release namespace with a PEM bundle at `ca.crt` to trust a
private issuer or another outbound TLS service. The chart mounts the bundle read-only
and sets `SSL_CERT_FILE` for the backend process. Restart the backend after replacing
the bundle. This cluster-operator setting is available in both editions; it does not
configure browser or session-pod trust. See [team login](/getting-started#move-the-quickstart-to-team-login).

## Telemetry collectors

Telemetry configuration is deployment-wide and available in both editions. Leave
`telemetry.otlpEndpoint` empty to record Claude Code usage in AgentHub. Session telemetry uses
the session callback credential when exporting to the internal backend.

Administrators can set `telemetry.otlpEndpoint` to an external OTLP/HTTP collector base URL;
the exporter appends `/v1/metrics`. That collector receives no session callback credential,
and those exports do not count toward AgentHub's Usage page or recorded budgets. Forwarding
from a custom collector to AgentHub is not supported. Network policy must also permit the
chosen collector destination.

After updating the server and runtime images, restart existing Claude sessions so they receive
the telemetry environment needed to keep recording usage. New sessions receive it at startup.

## Persistent session workspaces

`agent.repositoryProviderSwitchEnabled` defaults to `false`. Enable it to allow owner-reviewed
provider switches on temporary workspaces using clean, pushed repository commits and configured
object storage; it does not allocate PVCs. See [Switch provider](/provider-switching).

`agent.workspaceVolume.persistent` defaults to `false`. Enabling it gives new supported
Claude/Codex interactive terminal sessions a claim of `agent.workspaceVolume.size` (default
`10Gi`). `agent.workspaceVolume.storageClass` defaults to an empty string, using the cluster
default. Read [Switch provider](/provider-switching#operator-storage-settings) for lifecycle,
backup requirements, existing-session limits and reclaim-policy costs.
