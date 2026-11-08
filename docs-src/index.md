---
layout: home

hero:
  name: Open AgentHub
  text: Coding agents, running in your cluster
  tagline: Start a session, watch it work, approve what it wants to do — from the browser or from your phone.
  actions:
    - theme: brand
      text: Install
      link: /getting-started
    - theme: alt
      text: View on GitHub
      link: https://github.com/open-agenthub/open-agenthub

features:
  - title: Sessions in Kubernetes
    details: Every session is its own unprivileged pod with its own workspace, network policy, and mounted credentials.
  - title: Approve from anywhere
    details: Tool-permission prompts reach you in the web app, in Telegram, or in Signal — or skip them entirely with auto approve.
  - title: Bring your own agent
    details: Claude Code, Codex, Cursor, OpenClaw, and OpenCode, each with subscription or API-key billing, or your own model endpoint.
---

## Where to start

If you have a cluster, go to [Install](/getting-started). If you are upgrading an
existing release, read [Upgrading](/upgrading) first — there is one Helm pitfall that
bites almost everyone. Setting up an instance for a pilot team? Follow
[Pilot setup](/pilot-setup); for help, see [Support](/support).

New here? The [feature overview](/features) lists every feature, its edition and the page that
explains it. To learn the daily work, start with [Sessions](/sessions), [Projects](/projects),
the [Workspace](/workspace) and [Questions and approvals](/questions-approvals).

The most common setup tasks after installing:

- [Chat integrations](/chat) — get session updates and approve permissions from your phone.
- [Git integrations](/git) — let sessions clone and push without a manual token.
- [Provider login](/provider-login) — sign in to your agent's provider from a session.
- [Continue locally](/local-sessions) — take Claude Code or Codex history to your workstation.
- [MCP clients](/mcp) — connect external clients over HTTP or stdio.
- [Auto approve](/auto-approve) — let a session run its tools without asking.

## Editions

The core is AGPL-3.0. Enterprise features live under `ee/` in the repository and need a
valid license: session and project sharing, Slack, org-wide usage limits, groups and roles from
your identity provider, allowed agent kinds, and sharing MCP servers and skills with others.
Telegram and Signal are part of the free core. Without a licence the Enterprise features are
switched off and everything else keeps working.
