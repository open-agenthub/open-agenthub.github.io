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

## Integrations and other topics

| Feature | Edition | Who | Page |
| --- | --- | --- | --- |
| Install, first steps | Community | Operator | [Install](/getting-started) |
| Upgrade notes, API key without OIDC | Community | Operator | [Upgrading](/upgrading) |
| Telegram and Signal relays, desktop notifications | Community | Linked user | [Chat](/chat) |
| GitHub and GitLab tokens and OAuth connections | Community | Owner, operator | [Git](/git) |
| External MCP clients (remote HTTP, stdio) | Community | Everyone | [MCP clients](/mcp) |
| Continue a session on your workstation | Community | Owner | [Continue locally](/local-sessions) |
| Preview a page served from the session | Community | Owner | [Previewing a page](/preview) |
