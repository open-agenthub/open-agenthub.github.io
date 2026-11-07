# Upgrading

## Session telemetry

After installing the server and runtime update for session telemetry authentication, restart
existing Claude sessions so their usage continues to be recorded. New Claude sessions receive
the telemetry environment automatically. This applies in both editions.

If you use a custom `telemetry.otlpEndpoint`, metrics go to that collector without a session
callback credential and do not count in AgentHub. Leave the setting empty for AgentHub usage.
See [telemetry collectors](/chart-values#telemetry-collectors).

## The `--reuse-values` trap

`helm upgrade --reuse-values` reuses the values from the last release and merges your new
`--set` flags on top. What it does **not** do is pick up defaults that were added to the
chart since that release was installed.

So when a chart version introduces a new top-level key, an upgrade with `--reuse-values`
leaves that key unset — and any template that reads it unguarded fails:

```
Error: UPGRADE FAILED: template: open-agenthub/templates/signal-cli.yaml:1:14
  executing "open-agenthub/templates/signal-cli.yaml" at <.Values.chat.signal.enabled>:
    nil pointer evaluating interface {}.enabled
```

The error names the template, not the cause, which makes it a genuinely confusing dead
end. Nothing is wrong with your command; the values simply have a hole in them.

### The fix

Use `--reset-then-reuse-values` (Helm 3.14 and newer). It resets to the chart defaults and
then re-applies the values you supplied, so new keys arrive with their defaults:

```bash
helm upgrade agenthub agenthub/open-agenthub -n agenthub --reset-then-reuse-values \
  --set chat.telegram.enabled=true
```

### The better fix

Keep a values file per environment and pass it with `-f`. Then nothing is implicit:

```bash
# Export what the release currently has, once
helm -n agenthub get values agenthub -o yaml > my-values.yaml

# Edit it, then from here on
helm upgrade agenthub agenthub/open-agenthub -n agenthub -f my-values.yaml
```

That file holds secrets — database password, S3 keys, bot tokens — so keep it out of
version control.

## Image versions follow the chart

Since chart 1.19.0, `image.tag` is empty by default and means the chart's `appVersion`: chart
X.Y.Z runs the images of release X.Y.Z, and upgrading the chart moves every component — backend,
frontend, browser, renderer and all agent runtimes — to the new release. Check what a release
runs with:

```bash
kubectl -n agenthub get deployment agenthub-backend -o jsonpath='{.spec.template.spec.containers[0].image}'; echo
```

Earlier charts defaulted to `latest` with `pullPolicy: IfNotPresent`. Such an install ran
whatever image its nodes had pulled first, which could be newer than the chart, and an upgrade did
not move it. After upgrading to 1.19.0 or later it runs the matching release images instead.

If you set `image.tag` yourself, nothing changes: an explicit value always wins. To keep following
the newest build on purpose, set `image.tag: latest` together with `image.pullPolicy: Always` and
`agent.pullPolicy: Always`.

## Installs without OIDC: the API key

Releases up to 1.4.0 ran with no login at all when `oidc.authority` was empty, the chart
default: every request was the admin user `dev`. Later releases require a login, and the backend
**refuses to start** without one.

A plain `helm upgrade` (with `-f`, `--reset-then-reuse-values` or `--reuse-values`) handles this
for you. The chart generates an API key into the Secret `agenthub-api-key` and keeps it on every
later upgrade. Because the release existed before the key, the key acts as `dev`, so your
sessions, credentials and projects stay where they are. After the upgrade, read the key and
enter it when the UI asks:

```bash
kubectl -n agenthub get secret agenthub-api-key -o jsonpath='{.data.api-key}' | base64 -d; echo
```

Scripts send it as `Authorization: Bearer <key>`. Personal API tokens and the remote MCP keep
working; the MCP consent screen now asks for the key.

- **GitOps (`helm template`)**: the chart cannot read the Secret back there, so a generated key
  would change on every render. Create a Secret with a key of at least 32 characters, then set
  `auth.apiKey.existingSecret=<name>` and, on an existing install, `auth.apiKey.owner=dev`.
- **Rotating the key**: write a new value into the Secret's `api-key` and run
  `kubectl -n agenthub rollout restart deployment/agenthub-backend`.
- **Local development only**: `auth.insecureDevMode=true` restores the old open mode, with a
  warning in the log and in the UI.

Preview such an upgrade with `--dry-run=server`. With `--dry-run=client`, the chart cannot see
the existing Secret and shows a key and owner it would not actually use.

## Checking what an upgrade will change

A chart upgrade brings *every* change since the version you are on, not just the flag you
came for. Render it first and look before you apply:

```bash
helm upgrade agenthub agenthub/open-agenthub -n agenthub -f my-values.yaml --dry-run=client
```

New keys in the rendered ConfigMap are the quickest signal of how far the chart has moved.

## Rollouts and single-replica constraints

The backend defaults to two replicas. Enabling Telegram or Signal forces it to one,
because both integrations allow only a single consumer — see
[Chat integrations](/chat#one-replica-only). With one replica a rolling update briefly runs
the old and new pod at the same time, so expect:

- A short window where the messenger poller logs a conflict. It resolves itself as soon as
  the old pod terminates.
- No failover while the single pod restarts.

Neither loses data: Telegram buffers updates by offset for about 24 hours.

## Schema changes at startup

**Community and Enterprise · operator.** The backend creates and migrates its database schema
itself, one replica at a time, before it answers `/healthz`. Since 1.21.3
([issue #538](https://github.com/open-agenthub/open-agenthub/issues/538)), it remembers which
schema changes it has already applied, in a table called `schema_scripts`:

- **A restart with an unchanged schema runs no schema changes.** A replica no longer waits for
  long-running database transactions, and does not hold up the other replicas' requests while
  it starts.
- **The first start after an upgrade** applies what changed. If another transaction holds a
  table it needs, the replica waits at most 2 seconds at a time, backs off so that live requests
  get through, and tries again. In our tests, requests to the running replicas waited at most
  about 2 seconds per attempt. Each wait is logged with the transactions that were open:

  ```
  Schema script PostgresSessionStore waited 2000 ms for a table lock and backed off (attempt 1);
  retrying in 500 ms. Open transactions: pid 4711 (open-agenthub, idle in transaction, 42 s)
  ```

- **After 3 minutes** of such waits for one store, or once the replica's 10-minute startup budget
  is used up (before the chart's startup probe would restart it), the replica stops with
  `Schema script … could not lock its tables` and the same list of transactions. See
  [Troubleshooting](/troubleshooting#schema-script-could-not-lock-its-tables).

The first start of this release on an existing database applies every store's schema once,
because nothing has been recorded yet. Do not delete `schema_scripts`: without it, the next
start applies everything again.

After a downgrade to an older version, that version applies its own schema once on its first
start, and the next upgrade applies the current one once again. Both use the same bounded waits.
Releases before 1.21.3 do not use `schema_scripts` and apply their schema at every start, as
they always did.

## Version notes

What each release asks of an operator when upgrading to it. Releases not listed here need nothing
beyond a normal `helm upgrade`. When you skip versions, apply the notes of every release in between.

Many releases ship new agent runtime images. A running session keeps its old image until it
restarts: use **Update now** in the session header, or pause and resume the session. With
`agent.autoUpdateRuntimeImages` on, idle interactive sessions are updated automatically.

### 1.0.0

- From 0.13.x, new chart values arrive: helper containers (`sessionContainers.*`), model
  endpoints (`agent.modelEndpoints`), automatic runtime image updates, session resource limits
  and floors, and video limits (`files.maxVideoBytes`). Review them in your values file.
- Restart running sessions once so they start from the new runtime images.
- Optional: remove what earlier session deletions left behind in object storage. As an admin,
  call `POST /api/admin/session-storage-cleanup/dry-run`, review the listed prefixes, then send
  the returned token to `POST /api/admin/session-storage-cleanup/apply` within 15 minutes.

### 1.2.0

- Restart running sessions to get the new runtime images and the `/tmp` setup with the sticky bit.
- The integrated browser gets them the next time its pod is created (`browser_stop`, then
  `browser_start`).

### 1.3.0 and 1.4.0

Both releases fix provider login data in stored session archives and add an admin cleanup. Run the
1.4.0 cleanup; see [Archive cleanups after 1.3.0 and 1.4.0](#archive-cleanups-after-1-3-0-and-1-4-0).

### 1.5.0

**Breaking for installs without OIDC:** the backend requires an API key and refuses to start
without one. See [Installs without OIDC: the API key](#installs-without-oidc-the-api-key).
Installs with `oidc.authority` set are not affected.

### 1.6.0

- New values `backend.forwardedHeaders.knownProxies` and `knownNetworks`. They default to loopback
  and the private ranges; narrow them to your ingress controller's source range.
- New value `sharing.userSuggestionsEnabled` (Enterprise sharing), default `true`.

### 1.7.0

Restart running sessions to get the new runtime images and agent CLIs.

### 1.8.0

- The backend gets a startup probe that allows about 10.5 minutes, so one replica can wait for
  another replica's schema migration.
- Schema migrations run on the first start, one replica at a time. The first start also prunes
  orphaned rows and holds write locks on the share, MCP policy and Slack thread tables until it
  commits. Session and share writes can be delayed for that time, depending on table size.
- Restart running sessions to get the new runtime images and CLIs.

### 1.9.0

- The backend shares one Postgres pool per replica. New values `backend.database.maxPoolSize`
  (20) and `backend.database.lockPoolSize` (10).
- Check the connection budget before upgrading or scaling: up to 32 connections per replica, 64
  for two replicas, 96 during a rolling update. See [Chart values](/chart-values#the-connection-budget).
- **If you set `Maximum Pool Size` in `externalDatabase.connectionString`, `maxPoolSize` now
  overrides it.**

### 1.10.0, 1.10.1 and 1.12.1

Restart running sessions (for 1.10.1, Claude Code sessions) to get the updated runtime.

### 1.12.0

The chart narrows the egress rule that lets session pods reach object storage. If your external
object storage is reached **by DNS name on a port other than 80 or 443**, set
`agent.storageEgress.cidrs` to its networks, or add the port to `agent.extraEgressPorts`, **before
upgrading**. This matters most if you had the bundled storage enabled and reached external storage
on port 3900 through the old rule. Without it, affected sessions cannot save or restore their
state; stored objects remain. Watch for the warning in the `helm upgrade` output.

### 1.14.0

- The bundled Postgres is initialised in an init container. Existing data directories (a non-empty
  `PG_VERSION`) are left alone. Back up as usual before upgrading.
- New value `postgres.appArmorUnconfined` (default `false`), a last resort for hosts whose AppArmor
  profile denies Postgres its own signals. For production, use `externalDatabase.connectionString`.
- Restart running sessions to get the updated runtime images.

### 1.14.1

Deploy the new backend and frontend. Running sessions need no runtime update.

### Archive cleanups after 1.3.0 and 1.4.0

Releases up to 1.3.0 could store provider login data in session state archives in object storage:
Claude Code's configuration backups (up to 1.2.0), the Claude login file (0.1.0 to 0.4.0), and
temporary login copies of all five agents (0.13.0 to 1.3.0). 1.3.0 and 1.4.0 stop new archives
from containing them. Already stored archives need an admin cleanup.

The 1.4.0 cleanup, `provider-logins`, covers everything the 1.3.0 `claude-backups` cleanup
covers and more. Run it even if you already ran the 1.3.0 one; a repeat run is safe.

1. Deploy 1.4.0 or later.
2. Pause interactive sessions and wait until their pods are gone. Pausing returns before the pod
   has exited.
3. Run the cleanup per owner. `OWNER` is the session owner exactly as stored, normally the
   username; **Settings → Users & seats** lists it under **Admins & roles**. Authenticate as an admin
   with an OIDC access token, or with the API key on an install without OIDC. Preview first:

   ```bash
   curl -fsS -X POST https://hub.example.com/api/admin/session-storage-cleanup/provider-logins \
     -H "Authorization: Bearer $ADMIN_TOKEN" -H 'Content-Type: application/json' \
     --data '{"owner":"OWNER","apply":false}'
   ```

   Then send the same request with `"apply":true`. The result reports counts only: `scanned`,
   `missing`, `clean`, `rewritten`, `skipped`, `failed`. `skipped: 0` and `failed: 0` mean every
   archive was handled; otherwise repeat after the reported sessions have stopped.
4. Resume the sessions.
5. Scheduled sessions are skipped while their CronJob exists. Their archive is replaced only after
   a run on the new runtime has written it successfully; check that such a run completed.
6. Revoke provider logins at the provider if they may be affected: Claude logins used under 0.1.0
   to 0.4.0, and logins installed, refreshed or replaced while sessions ran 0.13.0 to 1.3.0.
   Cleaning an archive or deleting a session does not revoke a login.
7. Rotate credentials you configured as literal MCP header or environment values for Claude
   sessions.

The cleanup does not reach values running processes already loaded, copies a CLI made itself,
or your storage's object-version history and backups. Assess those separately.

## Shared protection keys and secret recovery

**Community and Enterprise · operator and affected secret owner.** For the release containing
[issue #458](https://github.com/open-agenthub/open-agenthub/issues/458), the Helm chart supplies
a stable wrapping Secret for a shared Postgres key ring. Use a values file so the new chart
defaults arrive. For offline/declarative rendering, configure
[`dataProtection.existingSecret`](/chart-values#shared-protection-keys) before upgrading.

**Values encrypted before the update with keys that are already lost need to be entered
again.** The update cannot recover a lost key. Unreadable values are retained, and list pages
remain available:

- In **Library → MCP servers**, a secret-unavailable hint tells the owner to edit the entry
  and re-enter the secret. Administrators repair organisation catalog entries. A configured
  secret remains marked as present until explicitly replaced or cleared.
- In webhook settings, an affected trigger shows a recovery hint. Recreate it, then update
  the delivery URL and secret in the repository's webhook settings. An administrator can
  instead restore the original keys before you recreate anything.
- Register affected session API sources again with their secrets. Restart sessions to get
  new gateway tokens, and repeat any pending storage-cleanup dry run.

The backend logs the number of unreadable stored secrets and recovery instructions. Operations
that need an unreadable secret fail clearly until repaired. Editing an MCP server without
supplying a new secret preserves the existing encrypted value.

If old file keys are still available, retain/export them **before replacing the old pods**.
The backend automatically attempts migration from the surviving default HOME key directory.
For an exported ring, mount it read-only and configure `DataProtection__LegacyKeysDirectory`
and `DataProtection__LegacyApplicationName` to the exact original application discriminator
(the old content-root path, normally including its trailing directory separator). Successfully
readable values are rewritten using the shared ring. Old transient tokens are reissued rather
than migrated. When several old pods had separate rings, preserve each export and migrate
with each original ring; a single export cannot recover another pod's lost keys.

Afterward, include both the database and wrapping Secret in your backup/restore procedure.
Do not delete or regenerate the Secret when retaining the database. A wrong/missing wrapping
identity stops backend startup rather than replacing the ring.
