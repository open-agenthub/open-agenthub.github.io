# Collect a support bundle

An operator can create a readable JSON file on their own machine, review it, and choose whether
to share it. Nothing is uploaded automatically. The default bundle contains no logs, names,
emails, session titles or session content.

**Edition:** Community and Enterprise · **Who:** cluster operator with an AgentHub administrator credential

This requires Open AgentHub 1.23.0 or later. Use the collector from the release you run
(replace `v1.23.0` with your version): [scripts/support-bundle.py](https://github.com/open-agenthub/open-agenthub/blob/v1.23.0/scripts/support-bundle.py).
Save it locally. Requirements: Python **3.9+**, kubectl **1.34+** (within one minor version of
your cluster), and Helm **3.12+** or **4.x**. No pip packages are needed.

## Create the file

Your current kubectl context must point to your installation. You need permission to read pods,
events, deployments and the `agenthub-config` ConfigMap in the release namespace. Helm also
needs its normal release metadata read permissions. The collector never requests a Kubernetes
Secret object directly, but Helm may read its stored release record. Raw Helm values stay in
memory and never become a file.

Forward the backend service in one terminal:

```sh
kubectl -n agenthub port-forward service/agenthub-backend 8080:80
```

In a second terminal, use Bash's hidden input to pass your credential through standard input:

```bash
read -r -s -p 'Administrator credential: ' support_credential; printf '\n'
printf '%s\n' "$support_credential" | python3 support-bundle.py \
  --namespace agenthub --release agenthub \
  --admin-url http://127.0.0.1:8080 --output support-bundle.json
unset support_credential
```

For API-key login, enter the installation's existing API key. For OIDC login, enter a current
access token for an administrator; a normal user's token receives **403**. Obtain that token
through your organisation's normal sign-in process. Do not paste the credential into a command
argument, enable shell tracing, or save it in the bundle. The collector never prints it. You can
also use your installation's HTTPS origin as `--admin-url`; redirects are refused.

The command creates a new file with owner-only permissions and refuses to overwrite an existing
file. Open and review the JSON before sharing it through a channel agreed with support. Remove
the local copy when you no longer need it. Collection errors produce a generic message so an
upstream error cannot echo credentials into diagnostic output.

## What is included

| Area | Included |
| --- | --- |
| Versions | Chart/application version and backend/configured runtime image tags; registry hosts and arbitrary custom tags are omitted |
| Pods | Component, phase, readiness, restart counts and pod counts in the release namespace; unknown component labels become `other`; no pod names |
| Events | Counts of fixed event reason categories in the last 60 minutes; no messages or object names |
| Helm values | Selected boolean and integer settings, such as replica counts, database pool sizes and feature flags; all other fields omitted |
| Database | Recognised `schema_scripts` names and application timestamps; no SQL or session data; `null`/`unavailable` if the tracking query fails |
| Licence | Verified edition, validity, expiry, included seat count and used seat count; no licence token, customer details or instance key |
| OIDC | Whether authority, client ID and audience are configured; no URLs, IDs or secrets |

Use `--event-minutes N` for a window from 1 to 1440 minutes. Unknown fields and values are omitted
instead of copied. Custom tags display as `omitted`. The sessions namespace is never queried separately. No session records, prompts, transcripts,
file contents, user lists, email addresses, secret values or Kubernetes Secret data are included.

## Optional backend logs

**Logs can contain personal data and user-chosen names. Agree on sending logs with the provider
beforehand (DPA), and review the file before sharing it.** Logs are absent by default.

Add `--include-backend-logs --log-lines 200` to the command to examine the last 200 lines from
each backend pod. The range is 1 to 10000. This requires pod log permissions. Only four exact
framework lifecycle messages are retained: application started, application shutting down,
production hosting environment and `/app` content root. Lines that look like tokens, unknown messages and multiline
continuation lines are discarded entirely. This intentionally excludes most application logs;
the bundle also reports how many lines were dropped. No agent/runtime, database or other
component logs are collected. A warning appears both on the terminal and in the JSON.
