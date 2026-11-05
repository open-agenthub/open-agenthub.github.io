# Continue a session locally

Take an existing conversation from AgentHub to a matching local checkout. The transfer
copies conversation history; it does **not** copy the repository, uncommitted project files,
or session attachments. Check out the project locally first and download attachments separately.

| Agent | Continue locally | Return the local conversation to AgentHub |
| --- | --- | --- |
| Claude Code | **Continue locally** in the web app, or the `session_take_local` MCP tool | The same dialog, or the `session_hand_back` MCP tool |
| Codex | Skill: `pull`, then `codex resume` | Not implemented |
| Other agents | Not available | Not available |

## Claude Code

From Open AgentHub 1.17, a Claude Code session moves to your computer and back without a
personal API token or a plugin. Three ways lead to the same result; pick the one that fits:

| Way | What you need | Who writes the files |
| --- | --- | --- |
| **Continue locally** button on the session page | `curl`, `tar` (built into Linux, macOS, Windows 10+) | A command you paste into a terminal |
| Remote MCP connection (OAuth sign-in) in your local Claude Code | The [built-in MCP endpoint](/mcp) | A command your local Claude Code runs |
| [Stdio MCP server](/mcp#local-stdio) with a personal API token | A checkout of AgentHub and Node | The MCP server itself |

Only the session owner can take a session local or hand it back. It works in every edition.

### What happens

1. **Take it local.** AgentHub pauses the session: its pod saves the conversation and stops, so the
   conversation is never answered in two places at once. Then it prepares the conversation for the
   local directory you named and writes it to `~/.claude/projects/`, where `claude --resume` finds it.
2. **Continue** with `claude --resume <id>` in that directory. Claude Code tells the model that the
   working directory changed; the conversation, including tool results, is the same.
3. **Hand it back.** Quit the local Claude Code first so the conversation is complete. AgentHub
   stores the local conversation as the session's own and resumes the session in the hub with
   every turn you took locally. Stop using the local copy afterwards.

The local directory should be a checkout of the same repository. The conversation moves, the
code does not: commit and push your local changes as usual.

### In the web app

Open the session and choose **⇩ Continue locally**.

1. Enter the **absolute** path of your local project directory, for example
   `/home/me/project` or `C:\Users\me\project`. The browser remembers it for this session.
2. Choose **bash / zsh** or **PowerShell**.
3. Under **Take it local**, choose **Pause and create command** (or **Create command** when the
   session is already paused), copy the command and run it in a terminal. It creates the
   directory if needed, downloads and unpacks the conversation, and starts `claude --resume`.
4. When you are done, quit Claude Code and, under **Hand it back**, choose **Create hand-back
   command**. Leave **Resume the session after the upload** ticked to continue in the hub right
   away. Run the command; it answers with the session's new state.

Each command contains a **single-use link that expires after 15 minutes**. It works once, for
this session and this direction only; create a new command if it expired. Treat it like a
password until it is used: anyone with the link can download the conversation.

### With the remote MCP endpoint

With AgentHub's [remote MCP endpoint](/mcp) connected to your local Claude Code, ask for example
*"take AgentHub session `a1b2c3` local into /home/me/project"*.

- `session_take_local` (`sessionId`, `directory`, `confirm`): without `confirm` it changes
  nothing and lists what it would do, so Claude Code can ask you first. With `confirm` it pauses
  the session and returns the link and the bash and PowerShell commands. Claude Code can run the
  command in its shell; start `claude --resume` in a new terminal yourself.
- `session_hand_back` (`sessionId`, `directory`, `resume`): returns the upload command.

The remote endpoint runs in the hub and cannot write to your disk, which is why it answers with a
command rather than writing the files.

### With the stdio MCP server

The [stdio MCP server](/mcp#local-stdio) runs on your computer with a personal API token and writes the files
itself, so there is no command to paste:

- `session_take_local` (`sessionId`, `directory`, `confirm`, `overwrite`) pauses the session
  (with `confirm`), writes the conversation and answers with the `resumeCommand` to run in a new
  terminal. It honours `CLAUDE_CONFIG_DIR` if you set one.
- `session_hand_back` (`sessionId`, `directory`, `resume`, `localSessionId`) packs and uploads
  the local conversation and resumes the session. `localSessionId` picks another local
  conversation, for example after `claude --resume --fork-session`.

### Limits

- The session needs a stored conversation, which it has once it has run.
- A session running in the hub cannot be handed back: pause it first. The hub refuses, because
  the running pod would overwrite the upload when it stops.
- A conversation already on your computer with other content is **not** overwritten: the pasted
  command stops at `tar`, the stdio tool answers `local_transcript_differs`. Hand that one back
  first, or pass `overwrite` to the stdio tool if you want to discard it.
- The links need **FrontendOrigin** to be set on the instance (the chart sets it); otherwise only
  the stdio server works.
- Session files and attachments are not part of the transfer; download them separately.

### The plugin (earlier releases)

Before 1.17, the [plugins repository](https://github.com/open-agenthub/plugins) offered the
**agenthub-sessions** plugin with `pull` and `push` commands and a personal API token. It still
works, but the steps above need neither the plugin nor a token in your shell.

## Codex: install and use the skill

Copy `codex/skills/agenthub-session-transfer` from the
[plugins repository](https://github.com/open-agenthub/plugins/tree/main/codex/skills/agenthub-session-transfer)
into your local Codex skills directory. The helper requires **Node 20+** and local Codex.
Ask Codex to use **agenthub-session-transfer**, providing the hub session ID or URL and
local checkout. It reads `AGENTHUB_URL` and `AGENTHUB_TOKEN`, or `~/.agenthub/cli.json`; create a
personal token in **Settings → API tokens** (it starts with `oah_`) and keep it out of chat messages.
If using the helper manually, replace `<skill-dir>` below with the installed
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
| `confirmationRequired` | The session is running; call the tool again with `confirm` after deciding to pause it. |
| `transcript_missing` / no stored state | The session needs an archived run; a never-started session has nothing to transfer. |
| `agent_not_supported` | Only Claude Code sessions move this way; for Codex use the skill. |
| `directory_invalid` | Give the absolute path of the local directory. |
| `session_live` | Pause the session in AgentHub, wait until it shows Paused, and retry. |
| `local_transcript_differs` / `tar` reports the file exists | A different local copy is there; hand it back first, or overwrite it on purpose. |
| `transcript_unrelated` | The local conversation does not continue this session; check the session ID and directory. |
| `link_invalid` (HTTP 404) | The link expired or was used; create a new command. |
| `origin_not_configured` | Ask the administrator to set FrontendOrigin, or use the stdio server. |
| `pod_still_stopping` | The session is paused but still saving; try again in a minute. |
| Codex helper: Not configured / HTTP 401 | Set the hub URL and a valid personal API token locally. |
| Codex helper: several transcripts | Inspect the choices and pass `--session <id>`. |

See the [Codex skill](https://github.com/open-agenthub/plugins/blob/main/codex/skills/agenthub-session-transfer/SKILL.md)
and the [design notes](https://github.com/open-agenthub/open-agenthub/blob/main/docs/session-transfer.md)
for implementation details.
