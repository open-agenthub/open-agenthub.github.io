# Chat integrations

Telegram and Signal notify you when a session waits for input or finishes, and let you
reply, approve permission prompts and start new sessions from your phone. Both are part of
the free core — [Slack](/slack) is an Enterprise feature.

A session shows up in chat only after one of its hooks reports that it is waiting for input.
That happens in **interactive** Claude, Codex, Cursor and OpenCode sessions. Autonomous and
scheduled sessions do not wait for input, so they never open a conversation on their own.
The exception is a session you started from the chat with `/new`. **OpenClaw sessions never
show up in chat** because OpenClaw has no hook for it. Cursor sessions show up, but their
permission prompts are not sent to chat: Cursor decides approvals from its own allowlist.

**Edition:** Community · **Who:** the operator enables the bots; each user links their own chat.

Long answers are split across several messages. Permission prompts expire after about
30 minutes; after that, answer in the web terminal.

## One replica only {#one-replica-only}

Both integrations require `backend.replicas=1`. Telegram's `getUpdates` and the Signal
receive socket each allow exactly one consumer, and a second poller would fight the first
for every update. The chart refuses to render otherwise:

```
Error: chat.telegram/chat.signal require backend.replicas=1
```

The backend default is **2**, so enabling chat halves it. That is a real availability
trade-off: no failover, and a brief gap during rolling updates. Nothing is lost when the
pod restarts — Telegram buffers updates by offset for roughly 24 hours.

## Telegram

### 1. Create the bot

Talk to [@BotFather](https://t.me/BotFather), create a bot, and copy the token. It looks
like `123456789:AAF…`.

### 2. Enable it

```bash
helm upgrade agenthub agenthub/open-agenthub -n agenthub --reset-then-reuse-values \
  --set chat.telegram.enabled=true \
  --set-string chat.telegram.botToken=<token> \
  --set backend.replicas=1
```

Use `--set-string` for the token: it contains a colon, and `--set` would try to be clever
about it.

Without Helm, the equivalent environment variables are `Chat__Telegram__Enabled=true` and
`Chat__Telegram__BotToken=<token>`.

### 3. Verify it works {#verify-telegram}

The backend is quiet on success, so "no errors in the log" is the expected state and not
much of a signal. Ask Telegram instead — the backend publishes the bot's command menu at
startup, so if the commands are registered, the connection works end to end:

```bash
curl -s "https://api.telegram.org/bot<token>/getMyCommands"
```

```json
{"ok":true,"result":[
  {"command":"link","description":"Link this chat to your AgentHub account"},
  {"command":"new","description":"Start a new session: /new [+repo] <prompt>"},
  {"command":"repos","description":"List your GitHub/GitLab projects"},
  {"command":"sessions","description":"List sessions in this chat"},
  {"command":"use","description":"Choose the session for plain replies; it stays chosen"},
  {"command":"unpin","description":"Plain replies follow the newest session again"},
  {"command":"status","description":"Show session status"}]}
```

An empty `result` means the backend never reached Telegram. Check the log for the giveaway
line:

```bash
kubectl -n agenthub logs deploy/agenthub-backend | grep -i telegram
```

`Telegram long polling not started (no bot token / disabled)` means the configuration did
not arrive. A `Conflict: terminated by other getUpdates request` warning means two pollers
are running — expected for a few seconds during a rolling update, a problem if it persists
(check `backend.replicas`).

### 4. Link your account

Each user links themselves: **Settings → Notifications → Telegram notifications →
Generate link code**, then click **Open in Telegram**, or send `/link <code>` to the bot
directly. The code expires after 10 minutes.

### Per-session forum topics

Optional, and worth it if you run several sessions at once. Create a Telegram group, turn
on **Topics**, add the bot as an admin with the **Manage topics** permission, and send
`/link <code>` in the group. Every session then gets its own topic.

::: warning
Everyone in a linked group can reply to sessions and approve permission prompts. A `/use`
choice applies to the whole group, not only to the person who sent it.
:::

### Commands

Each chat message names its session as `Name (#ab12)`. The `#ab12` part is the session's
tag: the first characters of its id.

| Command | Effect |
| --- | --- |
| `/link <code>` | Link this chat to your account |
| `/new [+repo …] <prompt>` | Start a new autonomous Claude session that works on the prompt. Leading `+name`, `+group/name`, `+name#branch` or `+https://…` tokens attach repositories. |
| `/repos [query]` | List the projects of your connected GitHub/GitLab accounts |
| `/sessions` | List this chat's sessions, most recent activity first, at most 15 |
| `/use #ab12` | Send plain replies to that session until you choose another. Works with or without `#`, any letter case. |
| `/unpin` or `/use auto` | Plain replies follow the newest session again |
| `/status` | Show the session's status, pending permission and link |

Telegram accepts every command except `/link` with a `!` prefix as well, so `!status` and
`/status` do the same thing.

### Which session a message goes to

Plain messages are typed into a session's terminal. The session is chosen in this order:

1. In a forum group, the session whose topic the message is in.
2. The session of the message you reply to.
3. The session you chose with `/use`.
4. Otherwise, the session that posted most recently.

`/use` keeps its choice even when other sessions post. `/new` moves an existing `/use` choice
to the session it just started.

### Deleted sessions

When a session is deleted, its chat links are removed. A message meant for it gets a reply
saying it was deleted, with a pointer to `/sessions` and `/use`. In a forum group its topic
stays as history. If the deleted session was the one you chose with `/use`, the message is
not sent to another session: choose a new one, or `/unpin`.

## Signal

### 1. Enable it

This deploys [signal-cli-rest-api](https://github.com/bbernhard/signal-cli-rest-api) with
a persistent volume for the account keys:

```bash
helm upgrade agenthub agenthub/open-agenthub -n agenthub --reset-then-reuse-values \
  --set chat.signal.enabled=true \
  --set-string chat.signal.number=+15551234567 \
  --set backend.replicas=1
```

### 2. Register the sender number

Once, via port-forward: `POST /v1/register/<number>` followed by
`/v1/register/<number>/verify/<token>` with the SMS or voice code. You can also link it as
a secondary device by QR code. The exact commands are in the comment block of
[`templates/signal-cli.yaml`](https://github.com/open-agenthub/open-agenthub/blob/main/helm/open-agenthub/templates/signal-cli.yaml).

The image tag is pinned on purpose — the account registration and keys live on the PVC, so
check the signal-cli-rest-api release notes for migration steps before bumping it.

### 3. Link your account

Each user enters their number under **Settings → Notifications → Signal** and confirms the
six-digit code sent via Signal.

### Reply routing

**Quote** a session message to answer that session. Unquoted messages go to the session you
chose with `!use`, or else to the session that posted most recently. React 👍/👎 on a
permission prompt to allow or deny, and quote-reply `always` for allow-always.

Signal accepts commands with the `!` prefix only:

| Command | Effect |
| --- | --- |
| `!new [+repo …] <prompt>` | Start a new autonomous Claude session. Leading `+name` tokens attach repositories. |
| `!repos [query]` | List your GitHub/GitLab projects |
| `!sessions` | List your sessions, most recent activity first, at most 15 |
| `!use #ab12` | Send unquoted messages to that session until you choose another |
| `!unpin` or `!use auto` | Follow the newest session again |
| `!status` | Show the session's status |

Deleted sessions work as they do on Telegram.

Not tested: delivery through a real Telegram or Signal account. These features were
tested against a recorded stand-in of the Telegram Bot API, and Signal's `!use` only in
unit tests.

## Desktop notifications

A browser notification when a session waits for input or finishes. Enable it per device
under **Settings → Notifications** — no cluster configuration needed.
