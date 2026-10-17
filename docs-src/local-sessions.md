# Continue a session locally

Take an existing conversation from AgentHub to a matching local checkout. The transfer
copies conversation history; it does **not** copy the repository, uncommitted project files,
or session attachments. Check out the project locally first and download attachments separately.

| Agent | Continue locally | Return the local conversation to AgentHub |
| --- | --- | --- |
| Claude Code | Plugin: `pull`, then `claude --resume` | Plugin: `push`, with the hub session paused |
| Codex | Skill: `pull`, then `codex resume` | Not implemented |
| Other agents | No helper described here | No helper described here |

The helpers live in the [plugins repository](https://github.com/open-agenthub/plugins),
separately from the AgentHub release. Both read `AGENTHUB_URL` and `AGENTHUB_TOKEN`, or
`~/.agenthub/cli.json`. Create a personal token in **Settings → API tokens**; its value
starts with `oah_`. Configure it locally and keep it out of chat messages and screenshots.
An [MCP connection](/mcp) does not automatically configure these download helpers.

## Claude Code: install the plugin

Requires Node on your workstation and a local Claude Code installation. Run:

```bash
claude plugin marketplace add open-agenthub/plugins
claude plugin install agenthub-sessions@open-agenthub
```

The plugin provides the **session-transfer** skill. Ask Claude Code to continue an AgentHub
session locally, giving the hub session ID and the matching local project directory.
The plugin version verified for this guide is **0.1.1** (MIT).

### Configure and choose a session

The following commands run in the plugin context, where `CLAUDE_PLUGIN_ROOT` points to
`plugins/agenthub-sessions`. For manual use, replace that variable with the installed
plugin's absolute path.

```bash
node "${CLAUDE_PLUGIN_ROOT}/scripts/agenthub-session.mjs" login --url https://hub.example.com --token <personal-api-token>
node "${CLAUDE_PLUGIN_ROOT}/scripts/agenthub-session.mjs" list
```

### Pull and continue

Pause the hub session before continuing locally so two agents do not work on the same
conversation. From your matching local checkout, run:

```bash
node "${CLAUDE_PLUGIN_ROOT}/scripts/agenthub-session.mjs" pull <hub-session-id>
```

The helper rewrites the transcript's working-directory metadata for this checkout and
prints a `claude --resume <id>` command. Run that command in a new local Claude Code
session from the same directory. Use `--dir <path>` to choose another checkout explicitly.
Existing local transcripts with different content are protected from overwriting.

### Return to AgentHub

Keep the hub session paused, finish your local work, then run from the same checkout:

```bash
node "${CLAUDE_PLUGIN_ROOT}/scripts/agenthub-session.mjs" local
node "${CLAUDE_PLUGIN_ROOT}/scripts/agenthub-session.mjs" push <hub-session-id>
```

Verify that the local transcript belongs to the hub session you intend to replace. Push
replaces the stored conversation while retaining the rest of the archived agent home.
Resume the session in AgentHub afterwards. Uploads to a Running or Pending session are
rejected with HTTP 409: a live pod would overwrite the upload when it next persists state.
Repository changes must be transferred separately, for example through your normal Git workflow.

## Codex: install and use the skill

Copy `codex/skills/agenthub-session-transfer` from the
[plugins repository](https://github.com/open-agenthub/plugins/tree/main/codex/skills/agenthub-session-transfer)
into your local Codex skills directory. The helper requires **Node 20+** and local Codex.
Ask Codex to use **agenthub-session-transfer**, providing the hub session ID or URL and
local checkout. If using the helper manually, replace `<skill-dir>` below with the installed
skill's absolute path. Configure the hub URL and personal token locally first.

```bash
node <skill-dir>/scripts/agenthub-codex.mjs list --json
node <skill-dir>/scripts/agenthub-codex.mjs inspect <hub-session-id-or-url> --json
node <skill-dir>/scripts/agenthub-codex.mjs pull <hub-session-id-or-url> --dir <local-checkout> --json
```

The helper imports one Codex rollout, assigns a fresh local thread UUID, and rewrites its
working-directory metadata. Run the returned `codex resume <local-thread-id>` command
from your chosen checkout in a new Codex conversation. The hub ID and local UUID are different.
If needed, select a rollout explicitly with `--session <rollout-uuid>`.

This is an import only: it does not pause or change the hub session and provides no push
command. A running session can be copied from its latest stored snapshot, which may omit
newer turns. It does not restore pod authentication, configuration, hooks, MCP servers, or
skills. Desktop sidebar discovery may require opening the imported thread through Codex first.

## Troubleshooting

| Message or symptom | Next step |
| --- | --- |
| Not configured | Set the hub URL and personal API token locally. |
| HTTP 401 | Check whether the personal token is valid and has not been revoked. |
| No stored state | The session needs an archived run; a never-started session has nothing to transfer. |
| No compatible transcript | Use the helper matching the session's agent. |
| Several transcripts | Inspect the choices and pass `--session <id>`. |
| Claude cannot determine the remote directory | Pass `--remote-cwd <path>` with the pod's working directory. |
| Push returns HTTP 409 | Pause the hub session and wait for it to stop before retrying. |

See the [Claude skill](https://github.com/open-agenthub/plugins/blob/main/plugins/agenthub-sessions/skills/session-transfer/SKILL.md),
[Codex skill](https://github.com/open-agenthub/plugins/blob/main/codex/skills/agenthub-session-transfer/SKILL.md),
and [archive API design](https://github.com/open-agenthub/open-agenthub/blob/main/docs/session-transfer.md)
for implementation details.
