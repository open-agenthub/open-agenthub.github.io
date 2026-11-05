# Sign in to an agent provider

Sessions with **Subscription** billing use your own login at the agent's provider. You sign in
once, inside a session; AgentHub stores the resulting login for your account and restores it into
later sessions. Signing in to the AgentHub web app is a separate login.

**Edition:** Community · **Who:** every user, for their own provider logins.

## Sign in from the Workspace

For **Claude Code** and **Codex**, the sign-in happens in the Workspace of an Interactive session:

1. Create an Interactive session with the agent and **Subscription** billing.
2. When the CLI needs a login, a sign-in card appears in the conversation: *The agent CLI is
   waiting for its owner to sign in.* For Claude Code, type `/login` if the card does not appear
   by itself.
3. Open the link on the card and complete the sign-in in your browser. For a device code, the card
   shows the one-time code to enter there; when the provider shows you a code instead, paste it
   into the card.
4. The CLI continues by itself. **Settings → Credentials** now lists the stored account.

The card has one main action per step; **Open terminal**, cancel and copy are secondary. Values
shown during sign-in are kept out of the saved session state, and saving resumes once sign-in has
completed.

### Automatic sign-in for Claude sessions

A Claude session with no subscription login, no API key and no own model endpoint shows the
sign-in card at start, without typing `/login`. An expired or invalid stored login is not detected
this way: such a session starts as usual, and the CLI asks you to sign in again.

## Sign in from the terminal

Cursor, OpenClaw and OpenCode sign in in the session's terminal. Open the Terminal interface, or
**⌘ Agent terminal** in the Workspace, and run:

| Agent | Login in the session terminal |
| --- | --- |
| Claude Code | `/login` inside Claude Code |
| Codex | `codex login --device-auth` |
| Cursor | `agent login` |
| OpenClaw | `openclaw models auth add` |
| OpenCode | `opencode auth login`; choose the provider and complete its sign-in or enter its key |

For OpenCode Go, get the key from the OpenCode console and use it in the session's login
flow. OpenCode Go and Zen use a key even when your billing is a subscription.

For **API-key** billing, store the key in **Settings → Credentials** and choose API-key mode when
creating the session. A personal AgentHub `oah_` token is for the hub API, not an agent provider
key.

Do not copy a workstation's credential files into the pod or paste login tokens into an agent
chat.

## Several accounts per provider

**Settings → Credentials → Provider logins** lists your stored logins per agent. For each one you
can **rename** it, **make default** for new sessions, or remove it. When you have more than one
login for an agent, the **New session** dialog offers an **Account** choice.

## Usage limits and account failover

When a stored login reaches its provider's usage limit, AgentHub marks the account as at its limit
until the window resets. The mark shows in **Settings → Credentials**, and **clear limit** removes
it by hand.

- A running session that hits the limit is moved to another available login of the same
  provider, and you are notified. Turn this off per session with **Edit session → Switch account
  automatically at usage limit**; the account is then still marked, so new sessions avoid it.
- New sessions avoid an account at its limit, unless you picked that account yourself.
- Agents can check and switch accounts themselves with the `account_status` and `account_switch`
  tools (see Built-in tools inside a session).

How AgentHub notices the limit differs per agent: Claude Code reports its rate-limit windows; for
Codex, OpenClaw and OpenCode the CLI's own usage-limit notice is recognised. For Cursor, detection
uses conservative output patterns that are not verified against the CLI.

## Troubleshooting

Sign-in was tested with the pinned CLIs and test identities, not with real provider accounts. See
[Troubleshooting](/troubleshooting#provider-login) if login is unavailable, and
[MCP clients](/mcp) for signing an external client into AgentHub.
