# Usage and cost

The **Usage & cost** page shows how many tokens each of your sessions used and what the API-key
sessions cost, plus the CPU time, memory and network traffic of their pods. You can set yourself a
monthly API budget there. With Enterprise, admins can set budgets for the whole organisation, a
group or a single user.

**Edition:** Community (Usage page, personal budget) · Enterprise (organisation-wide limits) ·
**Who:** every signed-in user for their own sessions; admin for organisation limits

## Opening the page

Click **Usage & cost** in the sidebar. The home page also shows **Top spend by session**, with a
link to the full page. You only ever see your own sessions.

## What the page shows

| Card | Meaning |
| --- | --- |
| **API cost** | Money for API-key sessions, as the agent CLI itself reported it. |
| **Subscription usage** | Tokens (and turns, where the CLI records them) of sessions that run on a subscription login. No dollar amount: this counts against your plan's limits, not money. |
| **Tokens** | All tokens: input, output and cache. |
| **Compute** | CPU time of your session pods, and network traffic received and sent. |

Below that, **Token mix** splits all tokens into input, output, cache read and cache create.

**Cost by session** lists every session with its tokens, token mix, pod resources (CPU time, peak
memory, data received and sent) and a cost or usage column. The pill in that column says how the
session is billed:

| Pill | Meaning | Counts against the budget |
| --- | --- | --- |
| `api` | Billed to your stored API key. Shows the reported cost, or **not reported** if the CLI reports tokens only. | Yes |
| `sub` | Covered by a subscription login. Shows turns. | No |
| `self-hosted` | A [custom model endpoint](/sessions); no provider bill. | No |
| `auto` | **billing unknown**: an interactive Claude session with both a login and an API key stored, where the CLI asked which to use. | No |

Whether a session counts as API spend is decided by the credential the hub gave the session, not
by the cost figure the CLI sends. Claude Code and OpenCode also report a price-table cost for
subscription sessions; that figure does not count as spend.

## Which agents are recorded

| Agent | Tokens | Cost |
| --- | --- | --- |
| Claude Code | Yes, needs `telemetry.enabled` (default on) | Reported by the CLI |
| Codex | Yes | Not reported: the CLI computes no price |
| OpenCode | Yes | Reported by the CLI |
| OpenClaw | Yes | Reported by the CLI |
| Cursor | **Not recorded** | — |

Codex, OpenCode and OpenClaw usage is read from each CLI's own records in the pod about every 30
seconds and when the agent exits. Only the numbers leave the pod, never conversation content.
OpenCode does not count its own title-generation request, so its figures can be slightly below
what the provider bills.

For Claude Code, leave `telemetry.otlpEndpoint` empty to send metrics to AgentHub. If an
administrator selects an external collector, those exports do not count in AgentHub. See
[telemetry collectors](/chart-values#telemetry-collectors) for the deployment setting and limits.
After updating the server and runtime images, restart existing Claude sessions to receive the
telemetry environment needed to keep recording usage.

If the table says **No usage recorded yet**, check that `telemetry.enabled` is set on the server
for Claude sessions.

## Your monthly API budget

Under **Monthly API budget**, enter an amount in **My limit (USD/month)** and click **Save**. Leave
the field empty and save to remove your limit. The bar shows this calendar month's API spend (UTC)
against the limit that applies to you. When an admin limit is stricter than yours, the bar says
**set by your admin** and names its scope.

### What happens at the limit

Once this month's API spend reaches the limit, **new API-billed sessions are blocked**; subscription
sessions still work. In detail:

- Starting a session that would bill an API key is refused with *"Monthly API budget reached …
  Use a subscription session or raise the limit."* This applies when a session is created,
  resumed, restarted for a runtime update (**Update now**) or restarted to apply new resources,
  including sessions started from chat, webhooks or the API.
- Sessions that are already running are not stopped.
- Only agents whose CLI reports a cost are gated: Claude Code, OpenCode and OpenClaw. Codex and
  Cursor sessions are never refused, because their API use never adds to the budget.
- Subscription sessions, self-hosted endpoints and `auto` sessions with unknown billing are never
  refused. An unattended Claude session in Auto mode with an API key stored counts as API-billed,
  because the CLI then uses the key.

::: warning A budget, not a spending cap
The budget counts the API cost that the agents report. It is not a guarantee on your total
provider spend: running sessions continue, and Codex and Cursor costs are not counted.
:::

## Organisation-wide limits

With an Enterprise licence, admins set limits under **Settings → Usage limits & groups**:

- **Global limit**: an amount per user and month that applies to everyone.
- **Per-user and per-group limits**: choose **user** or **group**, enter the username or group
  name and the amount, then click **Add**. Groups come from your OIDC provider's groups claim
  (see [Administration](/admin#groups-from-the-oidc-token)).

For each user, the **strictest** limit wins: the lowest of the global limit, the limits of their
groups, their own user limit and their personal limit. Each limit applies to that user's own spend;
a group limit is not a shared pool for the whole group. Without a valid licence, only personal
limits apply.

## Related

- [Chart values](/chart-values): `telemetry.enabled`
- [Administration](/admin)
