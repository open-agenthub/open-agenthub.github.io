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
    details: Claude, Codex, Cursor, and OpenClaw, each with subscription or API-key authentication.
---

## Where to start

If you have a cluster, go to [Install](/getting-started). If you are upgrading an
existing release, read [Upgrading](/upgrading) first — there is one Helm pitfall that
bites almost everyone.

The most common setup tasks after installing:

- [Chat integrations](/chat) — get session updates and approve permissions from your phone.
- [Git integrations](/git) — let sessions clone and push without a manual token.
- [Auto approve](/auto-approve) — let a session run its tools without asking.

## Editions

The core is AGPL-3.0. Enterprise features live under `ee/` in the repository and need a
valid license: Slack, org-wide usage limits, and session sharing. Telegram and Signal are
part of the free core.
