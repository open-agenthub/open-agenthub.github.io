# Sessions

A session is one coding agent working in its own pod in your cluster, with its own workspace,
network policy and credentials. This page covers creating a session, the choices in the
**New session** dialog, and what you can change while it runs.

**Edition:** Community · **Who:** the session owner. People a session is
[shared](/sharing) with (Enterprise) can watch or type, but cannot change its settings.

## Session modes

| Mode | What it does | Typical use |
| --- | --- | --- |
| **Interactive** | You watch the agent and reply to it, in the [Workspace](/workspace) or the terminal. | Pairing, exploratory work |
| **Autonomous** | Works through the **Task** on its own and ends when it is done. | A well-described task you hand off |
| **Scheduled** | Runs the task on a cron schedule (UTC) as a Kubernetes CronJob. Each run works like an autonomous session. | Nightly dependency updates, reports |

A scheduled session's cron expression can be changed later in **Edit session**; the dialog shows
the next run in UTC. Schedule changes apply to future runs and leave a run in progress alone. To
change a scheduled session's agent, billing, policy or runtime settings, delete and recreate it.

## Agent and billing

Choose the agent per session: **Claude** (Claude Code), **Codex**, **Cursor**, **OpenClaw** or
**OpenCode**. An administrator can restrict which agents are offered (Enterprise, see
[Administration](/admin)).

**Billing** is independent of the agent and of the mode:

- **Subscription** uses your provider login. See [Provider login](/provider-login) for signing in
  and for choosing among several stored accounts.
- **API key** uses a key stored under **Settings → Credentials**. Only that key is given to the
  agent process. For OpenClaw you also pick which stored key it uses.
- **Own endpoint** points Claude, Codex or OpenCode at a self-hosted model server: enter the
  endpoint URL and the model name. The dialog names the protocol the agent expects. Cursor and
  OpenClaw cannot use an own endpoint.

Below billing, **Model** sets the model the session starts on and lists the models the chosen
account offers. See [Choosing a model](/models).

::: warning Credentials are visible to the agent
Whatever credential a session gets is readable by the agent and the tools it runs. Run only
repositories and prompts you trust while credentials are present.
:::

## The New session dialog

| Field | Notes |
| --- | --- |
| **Title**, **Description** | The description tells the other agents of the project what this one is for. |
| **Interface** | **Workspace** (conversation view) or **Terminal** (the agent's own console). The default comes from **Settings → Interface**. |
| **Task** | Required for Autonomous and Scheduled; an optional first message for an Interactive Workspace session. |
| **System prompt** | Standing rules appended to the agent's own instructions. |
| **Project** | Puts the session in a [project](/projects); **New project…** creates one on the spot. |
| **Secrets** | Which stored [secrets](/secrets) this session receives. |
| **Repositories** | One or more repositories to clone into the workspace, and which [git tokens](/git) the session gets. |
| **Auto-delete** | Delete the session on its own after a number of hours or days, counted from its start or from its last activity. |
| **Advanced** | Tool policy, [MCP servers](/mcp-servers), container image, resources, **Run as root**, **Auto approve**. |

### Tool policy for unattended sessions

Under **Advanced**, Autonomous and Scheduled sessions take an allow list: built-in tools and
patterns, full MCP tool names, and shell commands (exact commands for Claude, command prefixes for
Codex and the others; Cursor has no shell list). Empty fields allow nothing in that category.

When **Auto approve** is on, the allow list is a head start, not a boundary: a tool that is not on
it becomes an approval request, which auto approve then answers. With auto approve off, a tool
outside the allow list waits for your approval in the web app or in [chat](/chat); if nobody
answers before the wait ends, it is denied. Nobody watches an unattended session, so tick
**Auto approve** when it should not stop on such a request. Sessions created through the API or
an MCP client without an explicit choice get auto approve on for Autonomous and Scheduled mode.
See [Auto approve](/auto-approve).

The hub's own tools that only read the session's state or clean up after it do not need to be on
the allow list: `agent_inbox`, `agents_list`, `session_list`, `session_get`, `session_wait`,
`container_list`, `container_logs`, `container_stop`, `secrets_list`, `account_status` and
`port_list`. A session that may start a helper container can therefore always stop it again and
read its own messages. Tools that let a session do more (`session_create`, `container_run`,
`secret_request`, `port_request`, `agent_send` and the others) still need an entry. A block under
**MCP security** in the [Share dialog](/sharing) applies to all of them.

An `mcp__…` name in the general tool list counts for every agent, as it does in the MCP tool list.

### Container image and root mode

**Container image** runs the agent inside your own toolchain image; the agent runtime and terminal
transport are copied in at start. The image must be glibc-based (Debian, Ubuntu, Fedora and
similar); Alpine is not supported.

**Run as root** lets the agent install system packages (apt, `npm -g`). The pod stays
unprivileged otherwise. An operator can switch root sessions off for the whole instance
(`agent.allowRootSessions`). Without root, the agent's root filesystem is read-only: it can write
to its workspace, `$HOME` and `/tmp`.

### CPU and memory

**CPU request** and **Memory request** are reserved on the node. **CPU limit** and **Memory limit**
cap the session: above the limit CPU is throttled and the agent is stopped for memory. Memory is
given in `Mi` or `Gi`. An empty limit means the instance default; the operator sets the defaults
and the highest limit a session may ask for (see [Chart values](/chart-values)). Values that make
no sense, such as `10m` of memory, are refused when you save.

## Changing a running session

Open **Edit session** from the session list or the session header.

- **Title**, **Auto approve** and **Auto-delete** apply at once.
- **Switch account automatically at usage limit** applies at once (see
  [Provider login](/provider-login#usage-limits-and-account-failover)).
- **Image**, **Run as root**, resources and the **System prompt** apply at the next resume. For a
  change that needs it, the dialog offers **Restart now**: the session is paused and resumed, its
  state is saved and the conversation continues, but a turn in progress is interrupted.
- Repositories, git tokens, MCP servers and secret grants can be changed as well; the dialog says
  when a change needs a restart.

**Pause** stops the pod and keeps the conversation; **Resume** starts a new pod and continues it.
The workspace directory itself is not kept across a pause: push your work with git or save files
to the session's [files](/files).

## Duplicate a session

**Duplicate session** copies a session's configuration into a new, independent session: agent,
billing, project, repositories, policy, resources and, if you tick them, the MCP configuration and
saved MCP servers. It does not copy the conversation, files, sharing settings or browser cookies.

## Continue an autonomous run interactively

When an autonomous run has finished or stopped, the session offers **Continue it interactively?**
with **Open workspace** or **Open terminal**, and **Keep auto-approve** to keep approving tools
without asking. Claude, Codex and OpenCode continue the same conversation. Cursor and OpenClaw start
a new conversation in the same workspace: the files stay, the chat history does not.

## Runtime updates

After an upgrade, sessions started from an older runtime image are marked **outdated image**.
**Update now** restarts the session on the current image; it is paused and resumed like a restart.

An operator can turn on automatic updates for idle sessions (`agent.autoUpdateRuntimeImages`,
default off). Per session, **Edit session → Automatic runtime image updates** chooses
**Deployment default**, **On when safe** or **Off**. Automatic updates only replace a session when
its runtime confirms that the agent has finished its turn; sessions with a custom image keep that
image.

## Sessions that delete themselves

**Auto-delete** removes a session after the time you set, counted **after start** or **after last
activity** (opening it, typing or sending it a message restarts the countdown). The remaining time
is shown wherever the session is listed. The minimum is five minutes and the maximum 365 days.
Deleting a session also deletes its stored state and files.

## When a session cannot start

The session list and the Workspace show why a session cannot start in plain words: a failed clone
(naming the repository), an image that cannot be pulled, a pod that cannot be scheduled, a refused
resource request, or the agent's own last output when it exits with an error (for example an
expired login).

When the initial clone fails because a host cannot be resolved or reached, it is retried with
increasing waits for up to five minutes before the session fails with *Network error: could not
reach …*. Errors such as *repository not found*, denied authentication or an unknown branch fail at
once. A connection that hangs instead of failing is not covered by the retry. Fix the repository in
**Edit session** and resume.

## Helper containers

An agent can start helper containers next to its session, for example a database for the
migration it is writing. They run in a namespace of their own for that session, are never more
privileged than the session, are subject to its network policy, and are removed when the session
is paused or deleted. The agent manages them with built-in tools; see
[Built-in tools inside a session](/session-tools).

## Related pages

- [Projects](/projects): grouping, ordering and moving sessions
- [Workspace](/workspace): the conversation view
- [Questions and approvals](/questions-approvals)
- [Sharing](/sharing) (Enterprise)
