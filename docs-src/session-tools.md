# Built-in tools inside a session

Every session comes with a few built-in MCP servers, so the agent can work with the hub
itself. It can start and manage child sessions and message other agents. It can also clear
its own context, change provider accounts, ask you for secrets, run helper containers and
request network ports. You do not configure any of this. The tools show up in the agent's
tool list like any other MCP server.

**Edition:** Community, plus Enterprise for sessions shared by other users · **Who:** the
agent in a session, acting for the session owner

## The built-in servers at a glance

| Server | What it is for | More |
| --- | --- | --- |
| `agenthub_sessions` | Child sessions, agent messaging, context clear, accounts, secrets, helper containers | this page |
| `agenthub_network` | Asking for extra network ports | [Network ports](/network-ports) |
| `agenthub_files` | Files the agent shares with you, attachments, project files | [Files](/files) |
| `agenthub_browser` | The integrated browser | [Browser](/browser) |
| `skill-library` | The shared, versioned skill library | [Skills](/skills) |

Not every runtime image ships every server: `agenthub_files`, `agenthub_network`,
`agenthub_sessions` and `skill-library` are in all five; `agenthub_browser` is in all of them
except Cursor's. OpenClaw got `agenthub_sessions` and `agenthub_browser` with
[#439](https://github.com/open-agenthub/open-agenthub/issues/439); an OpenClaw session started
from an older runtime image has neither of the two. OpenClaw lists them under `openclaw mcp list`
in its terminal.

**Scheduled sessions** get none of the `agenthub_sessions`, `agenthub_network` and
`agenthub_browser` tools. `agenthub_sessions` is on by default. Operators can turn it off
with the chart value `spawnMcpEnabled: false`, which also removes the helper container tools.

## Child sessions

| Tool | What it does |
| --- | --- |
| `session_create` | Starts a child session (details below) |
| `session_list` | Lists this session's direct children |
| `session_get` | Reads one session by id |
| `session_wait` | Polls a session until it has `Succeeded` or `Failed`, or until a timeout (at most 24 hours) |
| `session_delete` | Deletes a descendant session: pod and record. Its own children are not deleted. |
| `session_convert` | Turns a finished or paused autonomous descendant into an interactive session that a person can take over |

`session_create` starts a **Claude**, **Codex** or **Cursor** child. The default mode is
**Interactive**: a person can watch the child and answer its questions, and tool requests
outside its allow list wait for approval. **Autonomous** is meant for unattended work, where
such requests are approved automatically. `autoApprove: true` approves them in an
interactive child without making it unattended. See [Auto approve](/auto-approve).

The child joins its parent's project and gets the same MCP servers, unless the call names
others. It can also be given:

- repositories, where a repository on a host the parent already pushes to gets the same
  Git provider, so the child can push;
- the provider login and Git tokens to use;
- a subset of the parent's secrets (`secretIds`);
- CPU and memory requests and limits, within the instance limits;
- a self-delete timer such as `"12h"` (`autoDeleteAfter`);
- `accountFailover: "off"`, to keep it on its account when that account hits a usage limit.

`session_convert` keeps the conversation for Claude, Codex and OpenCode. Cursor and OpenClaw start a new
conversation in the same workspace. It fails while the session is running or when the session
is not autonomous.

### Which sessions an agent can reach

Among its owner's own sessions, an agent can list, read and message:

- itself;
- every session in the same project;
- its parent chain (parent, grandparent, …);
- its descendants (children, grandchildren, …), in any project.

`session_delete` and `session_convert` work only on the session's own descendants. The agent
never reaches another user's sessions, except shared ones in the Enterprise Edition (below).

## Messaging other agents

| Tool | What it does |
| --- | --- |
| `agents_list` | The agents this session can reach: id, title (the agent's name), description, phase. Marks the session itself. |
| `agent_send` | Sends a message or task of up to 4,000 characters. `to` is a session id or a unique title. |
| `agent_inbox` | Fetches new messages, up to four per call. `waitSeconds` (up to 60) waits for new ones. |

By default a message waits in the receiver's inbox until the receiver calls `agent_inbox`.
Two flags change that:

- **`priority: true`** pushes the message straight into the receiver's running agent.
- **`interrupt: true`** first stops the receiver's current work, then pushes the message.
  It implies `priority`.

The result's `deliveredVia` says where the message ended up:

| `deliveredVia` | Meaning |
| --- | --- |
| `inbox` | Stored. The receiver reads it with `agent_inbox`. A priority message also ends up here when it could not be pushed, for example because the receiver is not running. |
| `injected` | Typed or written straight into the running agent |
| `mod` | Handed to Claude Code's fleet mod, which adds it to the running turn or submits it as the next prompt |
| `next_turn` | Accepted by the pod and handed over when the receiver's current turn ends |

How a message is delivered depends on the receiver's runtime and mode. Interactive Codex
and OpenCode sessions get even normal messages at the end of their turn. In autonomous
sessions without the Claude mod, messages wait in the inbox. Delivery does not guarantee that
the receiving model acts on the message.

### The ✉ Messages panel

The **✉ Messages** button in a session's header shows a badge with the messages its agent
has not received yet. The panel lists them by kind (message, priority, interrupt), sender
and time. While the session is live you can send it a message from there yourself.
Dismissing a tile only hides it in your browser. The agent still receives the message.

## Context, accounts and secrets

| Tool | What it does |
| --- | --- |
| `context_clear` | Clears this session's conversation after the current turn and starts the new one with a handover the agent writes (`followUp`, up to 16,000 characters). Applies only to the session itself. |
| `account_status` | Which provider account this session or a descendant runs on, whether it is at its usage limit, and your other stored accounts for the same provider |
| `account_switch` | Moves this session or a running descendant to another stored account. The agent restarts with that login and resumes its conversation. |
| `secrets_list` | Names this session's secrets and where to find each, as an environment variable or a file in `~/.secrets`. Never the values. |
| `secret_request` | Asks you for a secret the agent needs. You enter the value in the web app. The agent never sees it in the conversation. |

The Workspace keeps earlier turns above a **Conversation cleared** line, and memory and
skills stay. `context_clear` works with Claude, Codex (`/clear`) and OpenCode (`/new`). Not
tested: the full `context_clear` flow with OpenCode.

`secret_request` waits up to 30 minutes for your answer (10 by default). A file secret
appears in the running session. An environment variable is set only from the next start.
See [Secrets](/secrets).

## Helper containers

With `container_run` the agent starts a helper container next to the session, for example a
database, a queue or a service under test. `container_list`, `container_logs` and
`container_stop` manage them.

- A helper never has more rights than the session: it runs as uid 1000 (root only if the
  session runs as root), with no capabilities, a read-only root filesystem except `/tmp`,
  and no Kubernetes access.
- Its declared ports are reachable only from the session and its other helpers, at the
  `host` name `container_list` returns. The session's network rules apply to the helper too.
- Data lives in temporary volumes. Pausing or deleting the session deletes every helper.
- Operators set the per-session quota, allowed registries and size limits under
  `sessionContainers.*` in the chart, or turn helpers off with
  `sessionContainers.enabled: false`. Helper containers need Kubernetes 1.30 or newer.

## Network ports

The `agenthub_network` server has two tools. `port_request` asks you to open a port on the
instance allowlist: outbound (`egress`), or from the session browser to a server in the pod
(`browser_to_agent`). The call waits for your decision. `port_list` shows the ports already
opened. See [Network ports](/network-ports).

## Sessions shared by other users (Enterprise)

With the Enterprise Edition, `agents_list` also lists sessions other users shared with the
session's owner by name, directly or through a project share, with the access role. The
owner's own share rules apply, and they are checked again on every call, so a revoked share
stops working at once.

| Role | `agents_list`, `session_get`, `session_wait` | `agent_send` |
| --- | --- | --- |
| Viewer | yes, a reduced status without prompts or settings | no |
| Collaborator | yes, a reduced status without prompts or settings | normal priority only |

Priority and interrupt are refused for another user's session, and the message waits in that
session's inbox. Delete, convert, account switching, context clear, secrets and helper
containers never work on another user's sessions. Each message to another user's session is
recorded in an audit log with the sender, the receiver and the time, but not the text. Share
links never grant MCP access. See [Sharing](/sharing).
