# Sign in to an agent provider

Complete the provider CLI's own sign-in inside an **Interactive** session's **Terminal**.
AgentHub stores the resulting provider login for your account and restores it into later
sessions. Signing in to the AgentHub web app is a separate login.

## First login

1. Select the **Terminal** interface preference before creating your first session.
2. Create an Interactive session with your agent and **Subscription** authentication.
3. Follow the provider's login prompt. Use the command below if a login is needed.
4. Complete any browser or device authorization yourself, then check **Settings → Credentials**
   for the stored account.

| Agent | Login in the session terminal |
| --- | --- |
| Claude Code | `/login` inside Claude Code |
| Codex | `codex login --device-auth` |
| Cursor | `agent login` |
| OpenClaw | `openclaw models auth add` |
| OpenCode | `opencode auth login`; choose the provider and complete its sign-in or enter its key |

For OpenCode Go, get the key from the OpenCode console and use it in the session's login
flow. OpenCode Go and Zen use a key even when your billing is a subscription.

For **API-key** authentication, store the key in **Settings → Credentials** and choose
API-key mode when creating the session. A personal AgentHub `oah_` token is for the hub API,
not an agent provider key.

## Reuse and manage accounts

Stored provider accounts appear under **Settings → Credentials**, where you can remove
them. Select the appropriate stored account when starting a subscription session. Complete
a new terminal login when the provider requires it. Do not copy a workstation's credential
files into the pod or paste login tokens into an agent chat.

::: warning 1.0.0-rc.1: use Terminal for first login
A new session opened in the Workspace interface can lack a terminal, and Claude's
`/login` can report “isn't available in this environment”. Select the **Terminal** interface preference and create a new Interactive session there
to complete login; an existing Workspace chat session may have no Terminal tab. This is a prerelease issue tracked in
[issue #114](https://github.com/open-agenthub/open-agenthub/issues/114).
:::

This guide describes released login flows (stable **0.13.1**), with the prerelease workaround
marked above. Background renewal changes merged after that release are not a prerequisite
for these steps.

See [Troubleshooting](/troubleshooting#provider-login) if login is unavailable, and
[MCP clients](/mcp) for signing an external client into AgentHub.
