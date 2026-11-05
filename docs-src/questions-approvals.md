# Questions and approvals

An agent stops and waits for a person in two situations. It **asks a question**: a choice or
some free text, such as which of two approaches to take. Or it **asks for permission** to run a
tool. This page explains where both appear, who can answer, and how to reduce the interruptions.

**Edition:** Community · **Who:** the session owner answers permission requests. A Collaborator
on a [shared session](/sharing) (Enterprise) can answer questions too, but not permission
requests. Members of a linked Telegram group can answer from the chat (see [Chat](/chat)).

## Questions from the agent

When Claude Code, Codex or OpenCode asks a question with choices, the Workspace shows it in full,
with its options:

- Click an option to answer.
- An option such as *Type something* opens a text field: write your answer and send it.
- A multi-select question ticks options one by one and moves on with its own step button; at the
  end, **Submit answers** sends them. OpenCode shows a review of your answers first.
- If the question cannot be shown as buttons, the Workspace says so, and **Open terminal** opens
  the agent's console to answer there.

While a question is open, the session gets a **?** marker in the sidebar, with the question as its
tooltip, and its status reads **Question open**. The home page lists it under **Needs you**, and
the session list can be filtered by **Question open**. The marker disappears when the question is
answered or cancelled, at the end of the turn, when the context is cleared and on a restart. A
session that has simply finished its turn and waits for your next message shows *The agent is
waiting for your reply* instead, without a marker.

A question in a session you can only view does not count as needing you.

::: tip Not every agent asks this way
Cursor emits no question events, so its questions appear only in its terminal and get no marker.
The marker was checked with Claude Code and Codex; OpenCode uses the same question events.
:::

## Permission requests

In an Interactive session, a tool the agent wants to run raises a permission request, shown above
the conversation with what the agent wants to do:

| Button | Effect |
| --- | --- |
| **Allow** | Runs the tool this once |
| **Allow (don't ask again)** | Runs it and allows that tool for the rest of the session |
| **Allow everything** | Turns on [auto approve](/auto-approve) for the session and answers this request |
| **Deny** | Refuses the tool; the agent is told and continues |

The same request is sent to your linked [Telegram, Signal](/chat) or Slack chat, where
you can answer it as well. Whichever answer arrives first counts. A request nobody answers expires
after its waiting period. The agent CLI then falls back to its own permission prompt: in an
Interactive session it asks in its terminal, in an unattended session the tool is not run.

Where requests are raised depends on the agent:

- **Claude Code, Codex and OpenCode** ask AgentHub on every tool call, so switching auto approve on
  or off takes effect in the running session.
- **Cursor** and **OpenClaw** read the auto-approve setting once at start; changing it needs a
  restart.
- **OpenClaw** has no per-call hook: an interactive OpenClaw session asks in its own terminal only,
  and its requests do not reach the web app's buttons or the chat.

### Requests that come from AgentHub itself

Two other kinds of request appear in the same place:

- **Network ports:** *The agent asks to open network port …* when the agent wants to accept or make
  a connection on a port that is closed by default. See Network ports.
- **Secrets:** a banner when the agent asks for a secret with `secret_request`, with a link to the
  form where you enter the value. See Secrets.

### The account email check

Claude Code asks before a tool call would send the signed-in account's email address to the
network. In an Interactive session without auto approve, that question is shown in the terminal
and you decide. In Autonomous sessions and sessions with auto approve on, AgentHub declines it
automatically; auto approve is not treated as consent to share the email address. In permission
requests relayed to chat, the detected account email is replaced with `[account email]`.

## Fewer interruptions

- Use **Allow (don't ask again)** for tools you approve over and over.
- For unattended work, give the session an allow list under **Advanced** in the
  [New session dialog](/sessions#tool-policy-for-unattended-sessions).
- Turn on [auto approve](/auto-approve) for a container you would hand over anyway.

## Related pages

- [Auto approve](/auto-approve)
- [Workspace](/workspace)
- [Chat: Telegram and Signal](/chat)
