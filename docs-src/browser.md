# Integrated browser

A session can have its own visible Chromium. The agent starts it when it needs one, drives it
through built-in browser tools, and you watch — and, if you may, take over — the same desktop
beside the chat. Until the agent asks for it, a session has no browser and uses no browser CPU or
memory.

**Edition:** Community · **Who:** session owner and Collaborators control it; Viewers watch;
operators enable it and size it

## Starting a browser

There is no start button. Ask the agent to open a page, and it calls `browser_start` itself. While
the browser pod comes up, the pane says *Preparing browser…* and *The agent requested a browser.
It appears here automatically.* Once it runs, the pane opens beside the conversation and the
session bar shows a **Browser** button.

Each session has at most one browser. It keeps running until the agent calls `browser_stop`, or
the session is paused, finishes or is deleted.

### The agent's browser tools

Claude Code, Codex and OpenCode sessions get the built-in `agenthub_browser` MCP server; a user MCP
configuration cannot replace it. The Cursor and OpenClaw runtime images do not ship it, so those
sessions have no integrated browser. The OpenClaw gap is tracked in [#439](https://github.com/open-agenthub/open-agenthub/issues/439).

| Tool | What it does |
| --- | --- |
| `browser_start`, `browser_status`, `browser_stop` | Start, inspect and stop the session's browser |
| `browser_navigate` | Open a URL |
| `browser_snapshot` | Read the visible text and element references of the page |
| `browser_click`, `browser_type` | Click an element, type into a field |
| `browser_screenshot` | Capture the page |
| `browser_tabs` | List, select, open or close tabs |

Before each action the agent's tab is brought to the front, so you always see the page it is
working in.

::: tip Autonomous sessions
An autonomous session's allow list has to cover the browser tools, for example
`mcp__agenthub_browser__*` — unless auto-approve is on. See [Auto approve](/auto-approve).
:::

## Watching and controlling the browser

The pane streams the browser's desktop. Its status line tells you which access you have:

| Status | Who |
| --- | --- |
| *Live · shared control* | Owner, Collaborators, Collaborator share links — mouse and keyboard reach the page |
| *Live · view only* | Viewers and Viewer share links — the server refuses their input |

You and the agent share one desktop, so you can step in to sign in somewhere, solve a prompt the
agent cannot, or point at something. Access is checked again every two seconds: a revoked link or
a Collaborator downgraded to Viewer loses control of an open view.

If the connection drops, the pane reconnects on its own; Chromium keeps running meanwhile.

### Copy and paste

With control access, **Ctrl/Cmd+C**, **X** and **V** over the browser pane copy and paste plain
text between your own computer and the remote page. Only text is carried, up to 256 Ki characters;
password fields give nothing on copy. A copy made by one person never reaches others watching the
same browser. If your browser refuses clipboard access, the pane says so.

## Arranging the pane

- **Resize**: drag the seam between browser and conversation (25 to 75 %).
- **Hide**: the **×** on the BROWSER tab, or Esc, closes the pane — *the agent keeps it*. Reopen it
  with **Browser** in the session bar.
- **Phone**: Files, Browser and Agent become tabs.

### Pop out into its own window

Click **Pop out**, or drag the **BROWSER** tab onto *Drop here to pop out Browser* or release it
outside the app window. The browser opens in a separate window — for example on a second screen —
with mouse, keyboard and clipboard working there.

While it is popped out, the pane in the session is hidden and the conversation takes the width;
if Files is open, Files is shown. Return it with **Bring back** in the session, **Bring back to
session** in the window, or by closing the window. Closing the session view also closes its
pop-out. If your browser blocks pop-ups, the pane asks you to allow them and stays docked.

Not tested: where the window lands on a physical second monitor.

## Cookies are kept per session

With object storage configured, the browser's **cookies** are saved periodically and restored when
the browser starts again — after `browser_stop`, a pause or a resume. Only cookies: no history,
cache, downloads, local storage, saved passwords or browser profile. Deleting the session deletes
them; duplicating a session does not copy them. Without object storage every browser starts with a
clean cookie jar.

::: warning The agent sees what the browser sees
The agent can read and act on every page and cookie in its browser. Sign in to accounts there only
in sessions whose prompts, repositories, MCP servers and collaborators you trust.
:::

## Previewing what the agent builds

The browser can open a dev server running in the session itself — see
[Previewing a page the agent is building](/preview).

## Limits

- One window: pages that try to open a popup window get a tab instead. A window that still opens
  separately is reloaded as a tab, so a form POST result and its opener are lost.
- No GPU. WebGL works through software rendering; heavy 3D pages are slow with the default
  one-CPU limit.
- Network: the browser reaches DNS, HTTP and HTTPS, plus any ports the operator added.

## For operators

The browser is on by default (`browser.enabled: true`) and costs nothing until used. Setting it to
`false` removes the browser tools from every session.

| Value | Default | Meaning |
| --- | --- | --- |
| `browser.resources` | 250m / 512Mi requested, 1 CPU / 2Gi limit | Per browser pod |
| `browser.screen` | `2560x1600` | Desktop size |
| `browser.startupTimeoutSeconds` | `90` | How long a start may take |
| `browser.cookieCheckpointSeconds` | `60` | Cookie save interval |
| `browser.extraEgressPorts` | `[]` | Destination ports beyond 80/443 |
| `browser.previewPorts` | `[3000, 4173, 5173, 8000, 8080]` | Session ports the browser may open |

More in Chart values.
