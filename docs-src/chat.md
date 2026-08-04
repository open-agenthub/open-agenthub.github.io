# Chat integrations

Telegram and Signal notify you when a session waits for input or finishes, and let you
reply and approve permission prompts from your phone. Both are part of the free core —
Slack is an enterprise feature.

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
  {"command":"sessions","description":"List sessions in this chat"},
  {"command":"use","description":"Choose the session for plain replies"},
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

Each user links themselves: **Settings → Notifications → Telegram → Generate link code**,
then open the `t.me` deep link, or send `/link <code>` to the bot directly.

### Per-session forum topics

Optional, and worth it if you run several sessions at once. Create a Telegram group, turn
on **Topics**, add the bot as an admin with the **Manage topics** permission, and send
`/link <code>` in the group. Every session then gets its own topic.

::: warning
Everyone in a linked group can reply to sessions and approve permission prompts.
:::

### Commands

| Command | Effect |
| --- | --- |
| `/sessions` | List sessions in this chat |
| `/use <tag>` | Route plain replies to that session |
| `!status` | Show session status |

Plain messages are typed into the active session's terminal.

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

**Quote** a session message to answer that session; plain replies go to the newest session,
or the one picked with `!use`. React 👍/👎 on a permission prompt to allow or deny, and
quote-reply `always` for allow-always. Commands: `!sessions`, `!use <tag>`, `!status`.

## Desktop notifications

A browser notification when a session waits for input or finishes. Enable it per device
under **Settings → Notifications** — no cluster configuration needed.
