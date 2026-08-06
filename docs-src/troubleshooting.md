# Troubleshooting

## Helm

### `nil pointer evaluating interface {}.enabled`

An upgrade with `--reuse-values` did not pick up a chart key that was added after your
release was installed. Use `--reset-then-reuse-values`, or keep a values file and pass it
with `-f`. Full explanation in [Upgrading](/upgrading).

### `chat.telegram/chat.signal require backend.replicas=1`

Working as intended — see [one replica only](/chat#one-replica-only). Add
`--set backend.replicas=1`.

## Telegram

### Nothing arrives, and the log looks fine

The backend logs nothing on success, so silence is not evidence of anything. Query the bot
directly:

```bash
curl -s "https://api.telegram.org/bot<token>/getMyCommands"
```

An empty `result` means the backend never reached Telegram. See
[verifying Telegram](/chat#verify-telegram).

### `Telegram long polling not started (no bot token / disabled)`

The configuration did not reach the pod. Check both:

```bash
kubectl -n agenthub get cm agenthub-config -o yaml | grep Telegram
kubectl -n agenthub get secret agenthub-secrets -o jsonpath='{.data}' | grep -o Telegram
```

If the ConfigMap has no `Chat__Telegram__*` keys at all, your deployed chart revision
predates the chat integration — upgrade the chart, not just the values.

### `Conflict: terminated by other getUpdates request`

Two pollers are talking to the same bot. For a few seconds during a rolling update this is
normal. If it persists, `backend.replicas` is greater than 1, or a second deployment
(a dev cluster, a laptop) is using the same bot token. Use a separate bot per environment.

## Git connections

### The Connect buttons do not appear

The UI shows them only when at least one provider has a client id *and* a secret. Check:

```bash
curl -s https://<your-host>/api/config
```

`"gitEnabled": true` means the backend sees a usable provider.

### Connect just returns me to the start page

No error, no entry in the backend log — because the request never reached the backend. The
authorize URL was relative, so the browser navigated back into the app, the SPA fallback
answered with `index.html`, and the router rewrote the address bar.

The cause is a provider whose `baseUrl` is set to an **empty string** rather than left out:

```yaml
providers:
  - id: gitlab
    baseUrl: ""     # ← this, not "unset"
```

Omit the key entirely to use the public instance. Fixed in the chart and the backend since
this was found, but an older release combined with an explicit `baseUrl: ""` still shows
it. Check what actually reached the pod:

```bash
kubectl -n agenthub exec deploy/agenthub-backend -- printenv | grep BaseUrl
```

The variable should be absent, or hold a real URL — never present but empty.

### "The requested scope is invalid, unknown, or malformed"

GitLab only grants scopes that were ticked when the application was registered. Open the
application in GitLab and tick the ones your values file asks for — see
[Git integrations](/git#at-the-provider). GitHub cannot produce this error.

### OAuth breaks after every restart

`git.stateKey` is unset, so a random key is generated at startup and the signed state from
before the restart no longer validates. Set a fixed random string of 32+ characters.

### `redirect_uri` mismatch at the provider

The registered URI must match `https://<your-host>/api/git/callback/<provider-id>` exactly,
including the provider id from your values file. Also make sure you did not register the
OIDC login callback (`/auth/callback`) by mistake — see [Git integrations](/git).

## Sessions

### The agent is stuck waiting on a permission prompt

Prompts expire after about 30 minutes. Answer in the web terminal, in your messenger, or
switch on [auto approve](/auto-approve) — enabling it also resolves the prompts that are
already pending.

## Reading the logs

```bash
kubectl -n agenthub logs deploy/agenthub-backend --tail=200
kubectl -n agenthub logs deploy/agenthub-backend --since=5m | grep -i telegram
```

Bot tokens and client secrets are kept out of these logs deliberately. If you ever see a
credential in there, that is a bug worth reporting.
