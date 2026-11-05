# Feature inventory (audit for open-agenthub#431)

Audit of the user documentation against Open AgentHub 1.14.1. Sources: the main repository's
README, its `docs/` decision records, the release notes 1.0.0 to 1.14.1, and the web app's
settings and dialogs. **Status** is the state of this site before the audit: *exists*, *outdated*
(page exists but contradicts or misses released behaviour) or *missing*. **Planned page** is
where the feature is or will be documented.

Editions: **CE** = Community Edition (AGPL, no licence), **EE** = Enterprise Edition (licence).

## Sessions and projects

| Feature | Edition | Roles | Status | Planned page |
| --- | --- | --- | --- | --- |
| Interactive, Autonomous and Scheduled sessions; edit a schedule's cron expression | CE | owner | missing | sessions |
| Agents Claude Code, Codex, Cursor, OpenClaw, OpenCode; Subscription or API key per session | CE | owner | outdated (home page lists four agents) | sessions, index |
| Custom container image, run as root, CPU/memory limits on a running session | CE | owner; root can be disabled by the operator | missing | sessions |
| Custom model endpoints (self-hosted model server) | CE | owner | missing | sessions |
| Session expiry: delete after a lifetime or idle period | CE | owner | missing | sessions |
| Duplicate a session; convert an autonomous session to interactive | CE | owner | missing | sessions |
| Runtime image updates ("Update now", optional auto-update of idle sessions) | CE | owner, operator | missing | sessions |
| Startup failures in plain words; clone retries on transient network errors | CE | owner | missing | sessions |
| Session helper containers (e.g. a database) | CE | owner, agent | missing | sessions |
| Projects; create a project in the new-session dialog | CE | owner | missing | projects |
| Reorder sessions by drag and drop or keyboard; move sessions (also scheduled) between projects | CE | owner | missing | projects |
| Search and group the session list | CE | everyone | missing | projects |

## Workspace

| Feature | Edition | Roles | Status | Planned page |
| --- | --- | --- | --- | --- |
| Workspace and Terminal views, interface preference | CE | owner, collaborator | missing | workspace |
| Composer: slash commands, completion, next-message suggestions, attachments by paste and drag & drop | CE | owner, collaborator | missing | workspace |
| Pending-message queue with "Send now" | CE | owner, collaborator | missing | workspace |
| Changes view (per-file Git diff) | CE | owner | missing | workspace |
| Stopped state with Resume; "Session starting" state | CE | owner | missing | workspace |
| Messages panel (✉) and priority messages from the owner | CE | owner | missing | workspace |
| Agent questions answered in the Workspace; "?" marker and "Question open" status | CE | owner, collaborator | missing | questions-approvals |
| Permission approvals, allow always, allow everything | CE | owner, collaborator | exists (auto-approve) | auto-approve, questions-approvals |
| Auto approve | CE | owner | exists | auto-approve |
| Sign-in card in the Workspace; automatic sign-in for Claude sessions without credentials | CE | owner | outdated (provider-login still carries the 1.0.0-rc.1 Terminal warning) | provider-login |

## Sharing (Enterprise)

| Feature | Edition | Roles | Status | Planned page |
| --- | --- | --- | --- | --- |
| Share a session with a user (Viewer, Collaborator), user suggestions | EE | owner | missing | sharing |
| Share links with expiry, revoke | EE | owner | missing | sharing |
| Child sessions inherit the parent's share | EE | owner | missing | sharing |
| Share a whole project with a user or a group | EE | project owner | missing | sharing |
| "Shared with me" in the session list | EE | recipient | missing | sharing |
| Session-wide MCP restrictions | EE | owner | missing | sharing |
| Shared history (open PR #14, unreleased) | EE | recipient | PR #14 | sharing |

## Files, browser and network

| Feature | Edition | Roles | Status | Planned page |
| --- | --- | --- | --- | --- |
| Files pane: upload, previews (images, SVG, video, Office), download, delete | CE (delete by collaborators: EE) | owner; collaborator with file write | missing | files |
| Project files shared between the sessions of a project | CE | owner, agent | missing | files |
| Integrated browser: start on demand, clipboard, pop-out window, drag tear-off | CE | owner, collaborator | missing | browser |
| Preview a page served from the session pod | CE | owner | exists | preview |
| Network port requests and approvals | CE | owner, agent | missing | network-ports |

## Credentials, secrets and skills

| Feature | Edition | Roles | Status | Planned page |
| --- | --- | --- | --- | --- |
| Provider accounts, several per provider, usage-limit failover | CE | owner | outdated (no failover) | provider-login |
| Git tokens per host, chosen per session; OAuth connections | CE | owner, operator | exists | git |
| Secret store: files or environment variables, project selection, per-session grants | CE | owner | missing | secrets |
| Secret requests from the agent (`secret_request`) | CE | owner, agent | missing | secrets |
| Skill library: versions, project skills, live sync into sessions | CE (sharing with groups: EE) | owner, admin | missing | skills |

## Integrations

| Feature | Edition | Roles | Status | Planned page |
| --- | --- | --- | --- | --- |
| Telegram and Signal relays | CE | linked user | exists | chat |
| Session names in chat, `/use` pin, `/unpin`, `/use #tag`, deleted-session notices | CE | linked user | outdated (pre-1.8 commands) | chat |
| Slack relay, `!new`, `!repos` | EE | linked user, operator | missing | slack |
| Desktop notifications | CE | everyone | exists | chat |
| Outgoing notification webhooks and incoming webhook triggers | CE | owner | missing | settings |
| Remote HTTP MCP with OAuth; stdio MCP with a personal API token | CE | everyone | exists (PR #13 updates it) | mcp |
| Built-in tools inside a session: spawn sessions, fleet messaging, priority and interrupt, `context_clear`, account switch | CE | agent | missing | session-tools |
| Shared sessions through the sessions MCP | EE | agent of a recipient | missing | session-tools |
| Saved MCP servers attached per session; org MCP catalog | CE (catalog sharing: EE) | owner, admin | missing | mcp-servers |
| Continue a session locally | CE | owner | exists | local-sessions |
| Git integrations | CE | owner, operator | exists | git |

## Account, usage and administration

| Feature | Edition | Roles | Status | Planned page |
| --- | --- | --- | --- | --- |
| Usage and cost page, personal monthly API budget | CE | owner | missing | usage |
| Org-wide usage limits per group or user | EE | admin | missing | usage |
| Personal API tokens and scopes | CE | everyone | missing | settings |
| Account deletion | CE | everyone | missing | settings |
| Admin roles, users and seats, allowed agent kinds, groups, licence | CE/EE | admin | missing | admin |

## Operators

| Feature | Edition | Roles | Status | Planned page |
| --- | --- | --- | --- | --- |
| Install (quickstart, Helm) | CE | operator | exists | getting-started |
| API key without OIDC; insecure dev mode | CE | operator | exists | upgrading |
| Database pool sizes (`backend.database.*`), connection budget | CE | operator | missing | chart-values |
| Storage egress (`agent.storageEgress.cidrs`, `agent.extraEgressPorts`) | CE | operator | missing | chart-values |
| Bundled Postgres init container, `postgres.appArmorUnconfined`, external database | CE | operator | missing | chart-values |
| Forwarded headers (`backend.forwardedHeaders.*`) | CE | operator | missing | chart-values |
| Private CA for object storage (`agent.trustedCaConfigMap`) | CE | operator | missing | chart-values |
| Archive cleanups after 1.3.0 and 1.4.0 | CE | admin | missing | upgrading |
| Upgrade notes per release 1.0.0 to 1.14.1 | CE | operator | missing | upgrading |
