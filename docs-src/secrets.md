# Secrets

The secret store hands an agent API keys, tokens and key files without pasting them into the
conversation, where they would stay in the transcript, the scrollback and every chat message. You
store a secret once, choose which projects and sessions receive it, and the session gets it as an
environment variable or as a file in `~/.secrets`. An agent that is missing one can ask you for it.

**Edition:** Community · **Who:** each user manages their own secrets; the session owner grants
them and answers requests

## Storing a secret

Open **Settings → Secrets** and click **+ Add secret**.

| Field | Meaning |
| --- | --- |
| **Name** | The variable or file name the agent sees, e.g. `DEPLOY_TOKEN` or `service-account.json` |
| **Delivered as** | **Environment variable** or **File in ~/.secrets** |
| **Value** | Write-only: it is never shown again. When changing a secret, leave it empty to keep the stored value |
| **What it is for** | Optional, shown to you and in the session dialogs |

Limits: 32 secrets per user, 16 KiB per value, names up to 64 characters. Variable names use letters,
digits and `_`; file names may not start with a dot. Names the runtime sets itself are refused —
`AGENTHUB_*`, `HOME`, `PATH`, the agent CLIs' own variables such as `CLAUDE_*` or `CODEX_*`, and
others that change how processes load. If a tool insists on such a name, deliver the secret as a file or under
another name.

**Change** edits a secret, rename included. A renamed secret stays selected wherever it was.
**Remove** asks again and says how many sessions lose it.

### The same name twice

Two secrets may share a name — a production and a staging `API_KEY`, say — as long as no single
session would receive both. The project and session dialogs show the clash and refuse to save; so
does a rename that would create one.

### Where a secret is used

Under each secret, Settings → Secrets lists the **Projects** that select it and the **Sessions**
that receive it, with how: *via project …*, *selected for it*, *granted directly*, *inherited from
its parent*, *requested by the agent*, and *passed to child sessions*. A secret nobody uses shows
*Not used by any project or session.*

## Choosing who gets a secret

Selection works on two levels: the project picks, and each session can narrow it or add to it.

### For a project

Click the **⚿** (*Secrets*) button on a project in the sidebar. Each secret is either **Not
allowed** or **Sessions in this project**. Sessions in the project — and the child sessions they
start in it — receive what is allowed here, including secrets you add to the project later.

### For a session

The new, edit and duplicate dialogs, and the **Secrets** panel above a running session, have one
control per secret:

| Level | The session gets it | Its child sessions get it |
| --- | --- | --- |
| **Not allowed** | No | No |
| **This session** | Yes | No |
| **Also child sessions** | Yes | Yes |

Inside a project, the project's secrets start at **Also child sessions**. Lower one and the session
stops following the project; the dialog says so, and setting every project secret back follows it
again. Outside a project, a session starts with nothing. **This session** and **Also child
sessions** can also give a session a secret its project does not select.

A session started by another session never gets more than its parent holds.

## How the agent receives it

| Delivery | Where | Changes in a running session |
| --- | --- | --- |
| File | `~/.secrets/<name>`, read-only | Appear, change or disappear within about a minute |
| Environment variable | `$NAME` in the agent's process | Take effect at the next start |

When a variable changed, the session view, the sessions list and Settings → Secrets show a note
with **Restart now**. A restart interrupts a turn in progress, so it asks once more; the conversation
continues afterwards. Only a session running interactively is offered the restart. Pausing the session takes a value away at once.

The agent can list what it has with the `secrets_list` tool — names, delivery and location, never
values.

## When an agent asks for a secret

An agent that needs a secret it does not have calls `secret_request` with a name, file or variable,
and what it is for, instead of asking in the chat. You are notified like for a question:

- In the session: *The agent asks for a secret: `NAME`* with **Add it…** and **Refuse**.
- In Settings → Secrets, under *Asked for by your sessions*.
- In Slack, [Telegram or Signal](/chat), as a message with a link to the pre-filled form.
  The value never goes through a chat.

**Add it…** opens the form with the name, delivery and purpose filled in — or the stored secret of
that name, whose value you can keep. Saving stores the secret and grants it to **the requesting
session only**, not to its children or the project. You can widen that later.

The agent waits up to 10 minutes by default (at most 30) and then learns only *provided* — with the
name and where to find it — or *not provided*. It never sees the value through the tool. A file
appears in the running session; a variable needs a restart, which the page offers.

In an interactive session you may first see an ordinary tool approval for `secret_request`. A
session can have at most five open requests.

## Scheduled sessions

Scheduled sessions follow secret changes: a new project selection, a rename or a grant reaches the
next run; a run already in progress keeps its variables. If the schedule could not be updated, the
session shows a note with **Update schedule**.

## Deleting a secret fails closed

Removing a secret, narrowing a project or deleting a project rewrites the copies every affected
session reads. If a session's copy cannot be rewritten, all of that session's secrets are withdrawn
rather than leaving the old value behind; the session shows a notice with **Retry**. Only if even
that fails does Settings → Secrets report the removal as pending, with **Retry**.

What this does not cover: a process that already loaded a deleted value as a variable keeps it until
it restarts (the restart is offered), and copies the agent made itself — files it wrote, output it
uploaded — are not touched.

## Values stay out of the records

- No page or API response ever returns a value.
- Values of eight characters or more are replaced with `[secret:NAME]` in stored scrollback,
  transcripts, shared views and chat messages.
- The **live terminal is not masked**. Anyone with terminal input on a [shared](/sharing) session can
  read `~/.secrets` and the session's variables; the share dialog says so.
- An agent that has a secret can use it, copy it or send it wherever its network allows. Give
  secrets only to sessions you trust with them.

## Personal API tokens

A restricted personal API token lists which secrets it may hand to the sessions it creates; a token
that names none hands out none. See [External MCP clients](/mcp) and Settings.
