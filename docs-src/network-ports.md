# Network ports

Session pods start with almost no network access. When an agent needs a port that is closed —
to reach a database on 5432, or to show a dev server on an unusual port in the session browser —
it asks for it, and you decide. Approved ports stay open for that one session until it is
deleted.

**Edition:** Community · **Who:** the agent asks, the session owner approves; operators set
which ports may be asked for

## What is open by default

Every session pod runs behind a default-deny network policy. Without any request it can reach:

- DNS, HTTP (80) and HTTPS (443),
- SSH, for git,
- the hub itself, and the configured object storage,
- the session's own browser on the [preview ports](/preview), while a browser runs.

Everything else is closed, in both directions.

## How the agent asks

Every interactive and autonomous session gets the built-in `agenthub_network` MCP server with two
tools:

| Tool | What it does |
| --- | --- |
| `port_request` | Ask for one port and wait for the decision |
| `port_list` | List the ports already opened for this session |

`port_request` takes a **direction**, a **port**, a **protocol** (TCP by default, or UDP) and a
short **reason** that you will see:

| Direction | Opens | Example |
| --- | --- | --- |
| `egress` | Outgoing traffic from the session pod to that port, on any host | An external Postgres on 5432 |
| `browser_to_agent` | The session browser to a server in the session pod (TCP only) | The agent serves an app on 9000 and opens it in the browser |

You do not need to know the tool names; ask the agent to "connect to the database" and it will
request the port when it hits the wall.

## Approving a request

A request appears as a banner in the session, like a tool permission:

> The agent asks to open network port 5432 (outgoing traffic, TCP).

with the agent's reason below it. Your choices:

| Button | Effect |
| --- | --- |
| **Allow** | Opens the port for this session |
| **Allow (don't ask again)** | Opens it, and later requests for the same direction, port and protocol in this session are approved without asking |
| **Allow everything** | Opens it and turns on [auto approve](/auto-approve) for the session |
| **Deny** | Keeps it closed; the agent is told you denied it |

Only the session owner can answer. If you connected [Slack](/slack) or [Telegram and Signal](/chat),
the request reaches you there as well, with the same buttons.

The agent waits up to five minutes by default. If nobody answers, the request expires and the
agent is told to ask you to approve it and try again.

### When nobody is asked

- **Port not on the instance list** — denied immediately, without asking you. You cannot be
  talked into opening a port the operator did not allow.
- **Already granted** in this session — approved at once.
- **Auto approve on** — approved at once. Requests still have to be on the instance list.

## How long a port stays open

An approved port stays open **for the lifetime of the session**, including across pause and
resume. It applies only to that session's pods; no other session can use it. The rules are removed
when the session is deleted. There is no button yet to close a single granted port — delete the
session to remove its grants.

## Scheduled sessions

Scheduled sessions do not get the network tools: nobody is there to approve. Give them what they
need through the operator values below, or use an interactive session.

## Limits

- An egress grant opens the port to **every** destination, not to one host. Network policies work
  on ports and addresses, not hostnames.
- One request covers one port and one protocol; ranges cannot be requested.

## For operators

Which ports may be asked for is set in the chart. Being on the list is permission to *ask*; the
owner still decides each request. The defaults cover common databases and dev servers:

```yaml
agent:
  portRequests:
    enabled: true
    requestablePorts:
      - "3000-3010"
      - "3306"
      - "3900"
      - "4173"
      - "4200-4210"
      - "5000-5300"
      - "5432"
      - "6379"
      - "6443"
      - "7000-7300"
      - "8000-8010"
      - "8080-8090"
      - "9000-9100"
      - "27017"
```

Entries are single ports or `from-to` ranges. `requestablePorts: []` or `enabled: false` switches
requests off; every request is then denied. A port on the list that is missing is the more common
problem than one too many: the agent cannot tell "refused by the instance" from "impossible" and
works around it.

`6443` (the Kubernetes API) is on the list on purpose: session pods carry no cluster credential,
so reaching an API server grants nothing without a kubeconfig the session was given deliberately.

To open a port for **every** session without asking, use `agent.extraEgressPorts`; for the
browser, `browser.extraEgressPorts` and `browser.previewPorts`. See [Chart values](/chart-values).
