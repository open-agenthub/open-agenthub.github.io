# Upgrading

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
