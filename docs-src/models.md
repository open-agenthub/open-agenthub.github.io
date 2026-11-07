# Choosing a model

The **Model** field in the **New session**, **Edit session** and **Duplicate session** dialogs
sets the model a session starts on. Below the field the dialog lists the models the selected
account offers, with the controls each one has (reasoning effort levels, context size, image
input, fast mode) as the agent's own CLI reports them.

**Edition:** Community · **Who:** the session owner chooses; collaborators can refresh a shared
session's list; viewers of a [shared](/sharing) session (Enterprise) only read it.

## How to use it

1. Pick the agent, the billing and, for a subscription, the account.
2. Click a model in the list, or type any model id. Leave the field empty to start on the CLI's
   default.
3. **Refresh** asks the agent's CLI again, through one of your running sessions on the same
   account.

Changing the model in **Edit session** takes effect at the session's next start. Inside a running
session the CLI's own `/model` command still switches models, as before.

## Where the list comes from

AgentHub does not keep its own model list and does not ask the providers itself. The list is what
the agent's CLI reports **inside a session pod, with that session's login or key**, and it is
stored per user and per account:

| Agent | Source | Checked against the account? |
| --- | --- | --- |
| Claude | Claude Code's own model list | Yes for a subscription login (it shapes the list by plan); not for an API key |
| Codex | Codex's model list | Yes for a subscription login; not for an API key |
| Cursor | `agent models`, the account's list | Yes |
| OpenCode | OpenCode's models for the providers you are logged in to | No, it is a catalogue |
| Own endpoint | The endpoint's `/models`, asked from the session pod | Yes, it is the server's own list |
| OpenClaw | — | Type the model id; OpenClaw picks its model from the API key |

A running session reports its list shortly after it starts, so the dialog knows an account once
any session has run on it.

## What the status line means

| Status | Meaning |
| --- | --- |
| *This account's models* | The list came from the provider for this account. |
| *The CLI's models, not checked against this account* | The CLI's own list; a model the account cannot use fails at the first turn. |
| *No list for this account yet* | No session has run on this account. Type an id or leave it empty. |
| *may be out of date* | The list is more than a day old. Refresh to update it. |
| *The account's list was refused* | The provider refused this account's list; the CLI shows its built-in models instead, which the account may not be able to use. |
| *Could not read this account's models* | The CLI is not signed in, the key was refused or the endpoint could not be reached. Type an id instead. |

A model you chose stays chosen even when a later list no longer contains it; the dialog marks it
as not listed instead of switching models or accounts for you.

## Limits

- **Refresh** needs a running session on the same account. Without one the dialog says so; no pod
  is started just to read a list.
- For an own endpoint the hub never contacts the endpoint itself. Its list comes from a session
  pod on that endpoint.
- Cursor's list was not yet tested against a real Cursor account; if its output cannot be read,
  the dialog reports an error and the field stays free text.
- Viewers of a shared session see the session's stored list and chosen model, without any account
  name, e-mail or key, and cannot refresh it.

See also [Sessions](/sessions) and [Provider login](/provider-login).
