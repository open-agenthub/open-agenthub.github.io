# Slack

When a session waits for your input, Slack opens a thread for it. Your replies in that
thread are typed into the session, and you can approve permission prompts with buttons. You
can also start a new session from Slack with `!new`. The backend uses Socket Mode, which
connects out to Slack, so your instance needs no public endpoint for it.

**Edition:** Enterprise (valid licence required) · **Who:** operator (setup), every user
(their own notifications)

Telegram and Signal work the same way and are free in the Community Edition. See
[Chat integrations](/chat).

## What reaches Slack

A session's thread opens the first time the session reports that it is waiting for input.
The thread starts with a header: the session name, its mode, its id, its owner and an
**Open the session ↗** link. The agent's message follows as a quote, split into several
messages if it is long. Slack shows the agent's message, not the raw terminal output. The
web terminal has the full context.

Later questions, permission prompts and the final "finished" or "failed" line go to the
same thread. So does a notice when the session expires.

As on Telegram and Signal, only some sessions report that they are waiting:

| Runtime | Opens a thread | Permission prompts in Slack |
| --- | --- | --- |
| Claude, Codex, OpenCode | yes, in interactive sessions | yes |
| Cursor | yes, in interactive sessions (generic text) | no, Cursor uses its own allowlist |
| OpenClaw | never | no |

Autonomous and scheduled sessions never open a thread themselves. The exception is a
session started with `!new`. Its thread opens at once.

## Answering in a thread

- **Reply in the thread**: the text is typed into the session's terminal. A "working…"
  message stays up until the session's next update.
- **`!status`** in the thread: the hub answers with the phase, any pending question or
  permission, and the session link. Nothing is typed into the session.
- **Permission prompts**: three buttons, **Allow**, **Allow (don't ask again)** and **Deny**.
  The message then shows the decision and who clicked. A prompt expires after about 30
  minutes. After that, answer in the web terminal.

A reply to a session that is not running gets "Session is not running — cannot deliver the
reply."

### Who can answer

Only the session's owner can reply in its thread, send `!status` or press the permission
buttons. If the session is [shared](/sharing), its Collaborators can too; Viewers cannot.
This matters when the thread is in a channel (a channel override, the fallback channel, or
`!new` sent in a channel): everyone in the channel can read the thread, but nobody else can
drive the session from it.

The bot recognises you by your Slack profile email, which must belong to exactly one
AgentHub user; if two accounts share the email, nobody is recognised, the owner included. This
works even when you have turned off **Send me Slack notifications**, so you can still answer your
existing threads. Anyone else who replies or clicks gets a short note that only they can see,
once per session, and nothing they sent reaches the session. A Slack user whose email
matches no AgentHub account is told once how the matching works.

## Starting a session from Slack

Outside a session thread, the bot understands two commands. Send them in a direct message
to the bot or in a channel the bot is in:

| Command | Effect |
| --- | --- |
| `!new [+repo …] <prompt>` | Starts an autonomous Claude session that works on the prompt, and opens its thread right below. Leading `+name`, `+group/name`, `+name#branch` or `+https://…` tokens attach repositories. |
| `!repos [query]` | Lists the projects of your connected GitHub/GitLab accounts |

The bot finds your AgentHub account by your Slack profile email. That email must belong to
exactly one AgentHub user, and that user must not have turned off Slack notifications.
Otherwise the bot answers "I can't map your Slack account to an AgentHub user". Session
limits and usage budgets apply as they do in the web app.

## Where your notifications go

Each user decides under **Settings → Notifications → Slack notifications**:

- **Send me Slack notifications**: turn Slack on or off for yourself.
- By default, the bot messages you directly. It finds you by your account email. The
  section shows **✓ connected** when a Slack user with that email exists.
- **Channel override**: a channel or DM id such as `C0123ABCD`, to use instead of your
  direct messages.

The operator can also set a fallback channel (`ee.slack.channel`). It is used only for users
whose account has no email and who set no override.

## Deleted sessions

Deleting a session removes its Slack thread link. Afterwards, a reply in the old thread gets
"This session was deleted. This thread remains as its history." The hub remembers old threads
for up to 30 days. After that, replies in them are ignored.

## Setting it up

**Who:** operator. You need a Slack app with Socket Mode turned on, and two tokens:

| Token | Used for |
| --- | --- |
| Bot token (`xoxb-…`) | Posting, updating and deleting messages, finding users by email, opening direct messages |
| App-level token (`xapp-…`) | The Socket Mode connection |

The bot token needs the permissions for these Slack methods: `chat.postMessage`,
`chat.postEphemeral`, `chat.update`, `chat.delete`, `users.lookupByEmail`, `users.info` (including the email) and
`conversations.open`. To receive replies and commands, the app has to subscribe to message
events in direct messages and in the channels it should listen in. Permission buttons
need interactivity turned on. This list comes from the methods the backend calls. It was not
checked against a real Slack app.

```bash
helm upgrade agenthub agenthub/open-agenthub -n agenthub --reset-then-reuse-values \
  --set ee.slack.enabled=true \
  --set-string ee.slack.botToken=xoxb-... \
  --set-string ee.slack.appToken=xapp-...
```

| Value | Default | Meaning |
| --- | --- | --- |
| `ee.slack.enabled` | `false` | Turns the integration on |
| `ee.slack.botToken` | `""` | Bot token. Without it, nothing is posted. |
| `ee.slack.appToken` | `""` | App-level token. Without it, notifications go out but replies, buttons and `!new` do nothing. |
| `ee.slack.channel` | `""` | Optional fallback channel id |

The tokens are stored in the chart's Secret. Slack also needs an active Enterprise licence,
which an admin activates in the [admin area](/admin). It is not a chart value. Without a
valid licence the backend posts nothing and does not connect to Slack.

Unlike Telegram and Signal, Slack does not require `backend.replicas=1`. The chart enforces
that limit only for those two.

::: tip
If nothing arrives, check the backend log. `Slack Socket Mode not started (no app token /
disabled)` and `Slack Socket Mode not started: no valid enterprise license.` name the two
usual causes.
:::

Not tested: the 1.14.1 changes to deleted-session threads were not checked against a real
Slack workspace over Socket Mode.
