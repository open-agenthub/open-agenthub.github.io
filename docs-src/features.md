# Feature overview

Every user-facing feature of Open AgentHub, the edition it belongs to, who can use it, and the
page that explains it. It describes release 1.14.1.

**Community** features are free and open source (AGPL-3.0) and need no licence. **Enterprise**
features live under `ee/` in the repository and need a valid licence; without one they are
switched off and everything else keeps working.

Roles used on these pages:

| Role | Who |
| --- | --- |
| **Owner** | The person who created the session or project |
| **Collaborator** | Someone a session is shared with who may type into it (Enterprise) |
| **Viewer** | Someone a session is shared with who may only watch (Enterprise) |
| **Admin** | An AgentHub administrator |
| **Operator** | Whoever installs and configures the Helm chart |

## Sessions and projects

| Feature | Edition | Who | Page |
| --- | --- | --- | --- |
| Interactive, Autonomous and Scheduled sessions | Community | Owner | [Sessions](/sessions#session-modes) |
| Claude Code, Codex, Cursor, OpenClaw and OpenCode; subscription, API key or own model endpoint | Community | Owner | [Sessions](/sessions#agent-and-billing) |
| Tool policy for unattended sessions | Community | Owner | [Sessions](/sessions#tool-policy-for-unattended-sessions) |
| Own container image, run as root, CPU and memory limits | Community | Owner; root can be disabled by the operator | [Sessions](/sessions#container-image-and-root-mode) |
| Edit, pause, resume, restart a running session | Community | Owner | [Sessions](/sessions#changing-a-running-session) |
| Duplicate a session | Community | Owner | [Sessions](/sessions#duplicate-a-session) |
| Continue an autonomous run interactively | Community | Owner | [Sessions](/sessions#continue-an-autonomous-run-interactively) |
| Runtime image updates | Community | Owner, operator | [Sessions](/sessions#runtime-updates) |
| Auto-delete after a lifetime or idle period | Community | Owner | [Sessions](/sessions#sessions-that-delete-themselves) |
| Startup failures in plain words, clone retries | Community | Owner | [Sessions](/sessions#when-a-session-cannot-start) |
| Projects, inline project creation | Community | Owner | [Projects](/projects) |
| Reorder sessions by drag and drop or keyboard | Community | Owner | [Projects](/projects#reorder-sessions) |
| Move sessions, including scheduled ones, between projects | Community | Owner | [Projects](/projects#move-a-session-to-another-project) |
| Search, group and filter sessions | Community | Everyone | [Projects](/projects#find-sessions) |

## Workspace, questions and approvals

| Feature | Edition | Who | Page |
| --- | --- | --- | --- |
| Workspace and Terminal views | Community | Owner, Collaborator | [Workspace](/workspace#workspace-or-terminal) |
| Composer: slash commands, suggestions, attachments | Community | Owner, Collaborator | [Workspace](/workspace#the-composer) |
| Pending messages, Send now, Interrupt and send, queue | Community | Owner, Collaborator | [Workspace](/workspace#messages-that-wait) |
| Messages panel for messages between sessions | Community | Owner | [Workspace](/workspace#messages-from-other-sessions) |
| Changes view (Git diff) | Community | Owner, Collaborator, Viewer | [Workspace](/workspace#files-changes-and-the-browser) |
| Agent questions, “Question open” marker | Community | Owner, Collaborator | [Questions and approvals](/questions-approvals#questions-from-the-agent) |
| Permission requests: allow, allow always, deny | Community | Owner | [Questions and approvals](/questions-approvals#permission-requests) |
| Auto approve | Community | Owner | [Auto approve](/auto-approve) |
| Sign in to an agent provider | Community | Owner | [Provider login](/provider-login) |

## Sharing (Enterprise)

| Feature | Edition | Who | Page |
| --- | --- | --- | --- |
| Share a session with a named user, as Viewer or Collaborator | Enterprise | Owner | [Sharing](/sharing#share-with-a-named-user) |
| Share links with role and expiry | Enterprise | Owner | [Sharing](/sharing#share-links) |
| Child sessions inherit the parent's share | Enterprise | Owner | [Sharing](/sharing#child-sessions-inherit-the-share) |
| Share a whole project with a user or group | Enterprise | Project owner | [Sharing](/sharing#share-a-whole-project) |
| “Shared with me” in the session list | Enterprise | Viewer, Collaborator | [Sharing](/sharing#shared-with-me) |
| Session-wide MCP restrictions | Enterprise | Owner | [Sharing](/sharing#mcp-restrictions-for-the-whole-session) |
| Manage shares over the API and MCP | Enterprise | Owner | [Sharing](/sharing#managing-shares-from-an-api-client) |

## Files, browser, secrets and skills

| Feature | Edition | Who | Page |
| --- | --- | --- | --- |
| Files pane: upload, previews, download | Community | Owner, Collaborator; Viewer reads | [Session files](/files) |
| Delete session files | Community; Collaborators need Enterprise sharing | Owner, Collaborator | [Session files](/files#deleting-a-file) |
| Files from the agent, presenting a file | Community | Agent | [Session files](/files#files-from-the-agent) |
| Project files shared between sessions | Community | Agent | [Session files](/files#sharing-files-between-sessions-of-a-project) |
| Integrated browser, clipboard | Community | Owner, Collaborator; Viewer watches | [Integrated browser](/browser) |
| Preview a page served from the session | Community | Owner | [Previewing a page](/preview) |
| Pop the browser out, drag tear-off | Community | Owner, Collaborator, Viewer | [Integrated browser](/browser#pop-out-into-its-own-window) |
| Network port requests | Community | Agent asks, owner approves | [Network ports](/network-ports) |
| Secret store, project selection, session grants | Community | Owner | [Secrets](/secrets) |
| Secret requests from the agent | Community | Agent asks, owner answers | [Secrets](/secrets#when-an-agent-asks-for-a-secret) |
| Skill library, versions, live sync | Community | Everyone | [Skill library](/skills) |
| Share and publish skills | Enterprise | Admin; users if allowed | [Skill library](/skills#sharing-skills-enterprise) |

## Account, usage and administration

| Feature | Edition | Who | Page |
| --- | --- | --- | --- |
| Settings: profile, interface, credentials, notifications | Community | Everyone | [Settings](/settings) |
| Personal API tokens and token restrictions | Community | Everyone | [Settings](/settings#api-tokens) |
| Webhook triggers for pull and merge requests | Community | Everyone | [Settings](/settings#webhooks) |
| Account deletion | Community | Everyone | [Settings](/settings#deleting-your-account) |
| Usage and cost page, personal monthly API budget | Community | Everyone | [Usage and cost](/usage) |
| Organisation-wide usage limits | Enterprise | Admin | [Usage and cost](/usage#organisation-wide-limits) |
| Admin roles, Org MCP catalog, licence entry | Community | Admin | [Administration](/admin) |
| Seats, groups and roles from OIDC, allowed agents, skill publishing | Enterprise | Admin | [Administration](/admin) |

## Operators

| Feature | Edition | Who | Page |
| --- | --- | --- | --- |
| Chart values: images, database pools, bundled Postgres, storage egress, sign-in, sessions | Community | Operator | [Chart values](/chart-values) |
| Version notes and archive cleanups | Community | Operator, admin | [Upgrading](/upgrading#version-notes) |

## Integrations and other topics

| Feature | Edition | Who | Page |
| --- | --- | --- | --- |
| Install, first steps | Community | Operator | [Install](/getting-started) |
| Helm upgrades, API key without OIDC | Community | Operator | [Upgrading](/upgrading) |
| Telegram and Signal relays, desktop notifications | Community | Linked user | [Chat](/chat) |
| `/use`, `/unpin`, session names, deleted-session notices | Community | Linked user | [Chat](/chat#which-session-a-message-goes-to) |
| Slack relay, `!new`, `!repos` | Enterprise | Linked user, operator | [Slack](/slack) |
| Built-in tools inside a session: child sessions, messaging, `context_clear`, accounts, helper containers | Community | Agent | [Built-in tools](/session-tools) |
| Reach sessions shared with the owner through the sessions MCP | Enterprise | Agent | [Built-in tools](/session-tools#sessions-shared-by-other-users-enterprise) |
| Saved MCP servers, API URL servers, inline MCP config | Community | Owner | [MCP servers for sessions](/mcp-servers) |
| Org MCP catalog | Community; per-entry sharing Enterprise | Admin | [MCP servers for sessions](/mcp-servers#org-mcp-catalog-admins) |
| Share MCP entries with users and groups | Enterprise | Owner | [MCP servers for sessions](/mcp-servers#sharing-your-entries-enterprise) |
| GitHub and GitLab tokens and OAuth connections | Community | Owner, operator | [Git](/git) |
| External MCP clients (remote HTTP, stdio) | Community | Everyone | [MCP clients](/mcp) |
| Continue a session on your workstation | Community | Owner | [Continue locally](/local-sessions) |
