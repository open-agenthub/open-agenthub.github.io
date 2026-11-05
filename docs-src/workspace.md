# The Workspace view

The Workspace shows an interactive session's conversation as a chat: what you asked, what the
agent answered, and a compact log of the tools it used. Next to it you can open the session's
files, the Changes view and the integrated browser, and a terminal drawer when you need the
agent's own console.

**Edition:** Community · **Who:** the session owner. A Collaborator on a
[shared session](/sharing) (Enterprise) can read and write messages too; a Viewer can only read.

## Workspace or Terminal

Each session opens in one of two interfaces, chosen under **Interface** when you create it:

- **Workspace**: conversation, tasks and tools in one view.
- **Terminal**: the agent CLI's own console interface.

The default for new sessions is set per browser under **Settings → Interface**. You can switch a
running session between the two with the **Workspace** and **Terminal** buttons in its header,
without restarting the agent.

In the Workspace, **⌘ Agent terminal** opens the agent's console in a drawer below the
conversation, and **›_ Shell** opens a separate shell in the session's container. The shell is
only offered to the session owner.

## The conversation

- New messages appear live while the agent works. Long conversations open with the most recent
  part; **Load earlier messages** goes further back.
- **Find in conversation…** searches the messages that are loaded.
- Each message has **Copy** and **Quote** actions; **Quote** puts the text into your draft.
- Hover a time stamp for the full date and time.
- The conversation survives a pause, a restart and a runtime update, and it follows the agent's
  `/clear` and `/new`.
- Long links and inline code wrap; code blocks and tables scroll on their own.

## The composer

Type in **Give your agent a task…** and press **Enter** to send (**Shift+Enter** for a new line).

- **Slash commands:** type `/` to list the commands of the session's agent CLI, including custom
  commands and, where the CLI offers them, skills. Up and Down move the highlight, Tab or Enter
  complete it, Escape closes the list.
- **Suggestions:** when the CLI predicts your next message, it appears greyed out in the input.
  **→** or **Tab** accepts it into your draft; you still send it yourself. Typing dismisses it.
- **Attachments:** paste an image, drop files onto the composer, or use **＋ Attach files**. The
  files are uploaded to the session's files and the agent receives them with your
  message; images show as thumbnails in the conversation.
- **◼ Stop** interrupts the agent's current turn.

Your draft is kept per session while you look at another one.

## Messages that wait

When the agent is busy, a message you send is shown as pending until the agent takes it:

- **Send now** delivers it into the running turn as a priority message instead of waiting for the
  turn to end.
- **Interrupt and send** stops the agent's turn, and the agent then takes your message at once.
- **✕** stops showing it as pending.

While the agent is not ready yet (for example while the session is starting), messages go into a
queue above the composer, marked *Queued · will be sent when the agent is ready*. **Edit** puts
one back into the composer, **Withdraw** removes it.

## Messages from other sessions

The **✉ Messages** button in the session header (owner only) opens a panel with the messages
other sessions sent to this one, with a badge for how many are open. **Message this agent** sends
your own message; tick **priority** to deliver it into the running prompt now, and **interrupt**
to stop the current work first. How sessions message each other is described in
Built-in tools inside a session.

## Files, Changes and the browser

The session bar opens companion panes beside the conversation:

- **Files**: the session's files, with previews. See Session files.
- **Changes**, a view inside the Files pane: a per-file Git diff of the agent's work in the
  repositories under the workspace. It needs a running session.
- **Browser**: the integrated browser, once the agent has started it. See
  Integrated browser.

Drag the separator between the conversation and the pane to resize it between 25 % and 75 %; with
the keyboard, focus the separator and use the arrow keys. On a phone the panes take turns with the
conversation.

## Starting, waiting and stopped states

- **Session starting** shows the stage: waiting for the pod, then starting the agent. It ends
  when the agent can take input.
- An activity line shows whether the agent is working or waiting for you.
- When the session is paused, finished, failed or scheduled, the composer is replaced by a bar
  that says so. The owner gets **Resume** there. A finished autonomous run offers to
  [continue interactively](/sessions#continue-an-autonomous-run-interactively).
- If a CLI needs a sign-in, a sign-in card appears in the conversation; see
  [Provider login](/provider-login).

Questions and permission requests from the agent appear in the Workspace as well; see
[Questions and approvals](/questions-approvals).

## Limits

- The message-by-message conversation is available for Claude, Codex and OpenCode, which keep a
  native conversation record. For Cursor and OpenClaw the Workspace shows the cleaned terminal
  history instead, without per-message times; use the Terminal for those agents when you need the
  full console.
