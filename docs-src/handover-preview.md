# Handover preview

::: info Availability
This page describes the history and preview foundation in product PR
[#487](https://github.com/open-agenthub/open-agenthub/pull/487), tracked in
[#466](https://github.com/open-agenthub/open-agenthub/issues/466).
It is not available in 1.18.0. Publish this guide with the release containing that change.
:::

A handover preview lets a session owner prepare the exact text they would give another
provider: instructions, current task, decisions, pending work and source references.
The preview sends no conversation to a provider, starts no agent and changes no credentials.
This step provides an API preview; there is no provider-switch button in Workspace yet.

The preview is a **Community** feature for the **owner** of an interactive session using the
Terminal interface. Shared Collaborators, Viewers, peer agents and parent sessions cannot
request it on someone else's behalf. Enterprise sharing continues to control who can read
the conversation and does not grant handover authority.

## Prepare a preview

Send an authenticated web API request to `POST /api/sessions/{id}/handover-preview`, using
the same owner identity as your normal web API requests. This is not a personal-token
`/remote` endpoint or an in-session MCP tool. Replace `session-id` with your session ID;
`ACCESS_TOKEN` below is an access token for your installation's web API.

```sh
curl https://hub.example.com/api/sessions/session-id/handover-preview \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H 'Content-Type: application/json' \
  --data '{
    "target": "Codex",
    "instructions": "Keep the current task scope and check changes before committing.",
    "task": "Finish the settings page.",
    "decisions": "Use the existing settings components.",
    "pendingWork": "Verify saving and reopening the page.",
    "references": ["frontend/src/settings.vue:12", "https://example.com/spec"]
  }'
```

`target` accepts `Claude` or `Codex`. `instructions` and `task` are required.
`decisions`, `pendingWork` and up to 32 `references` are optional. Review the returned
`text`: it contains the complete framed selection, including the omission note.

The complete preview must fit **16,000 characters**, including headings and the omission
note. An oversized selection is rejected with HTTP 400; shorten it yourself. Instructions
and references are never silently truncated. Terminal control characters are rejected.
The fixed opening keeps a leading slash in selected text from becoming a CLI command.

References are retained as text. The preview does not open referenced files or URLs,
check that they exist, or attach their contents. Include needed details in your selection.
Do not select credentials or other material you would not want to send to a target provider.

## What is omitted

The explicit note lists earlier native messages, raw tool outputs, attachments, hidden
reasoning and native resume files. Only your selected plain text is part of the preview.
Historical coverage is reported as unknown; the preview does not pretend that the selection
contains every instruction from the old conversation.

`capacity` is `unknown`: a character count does not establish whether the target model has
enough context space. `switchingAvailable` is `false`, with a reason explaining that runtime
switching is not enabled and the workspace is ephemeral. There is no delivery acknowledgement,
pod replacement, target sign-in or automatic continuation. Autonomous, scheduled and streaming
chat sessions are refused. A missing or inaccessible session returns 404.

## Conversation history

The history foundation keeps execution segments in one session conversation. When later
runtime switching is enabled, a provider boundary will distinguish the segments; prior text
will stay history rather than automatically becoming the next provider's model context.
Existing sessions keep their native history and context-clear boundaries.

Existing single-execution sessions retain their current native full-history paging without
a new total limit. Only a combined view containing several executions is bounded to
5,000 entries and approximately one million characters;
an explicit omission boundary appears when earlier retained entries fall outside that view.
Individual provider projections have their own retention and field limits. A missing or
previously truncated native record cannot be reconstructed. History does not translate native
resume files between providers. Sharing links and roles continue to apply to the same session.

See [Workspace](/workspace), [Provider login](/provider-login) and
[Questions and approvals](/questions-approvals) for the existing session controls.
