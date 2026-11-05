# Sharing a session

Sharing lets other people open a session you own: they follow what the agent does and, if you
allow it, type into it as well. You can share one session with a named user, hand out a secret
link, or share a whole project, so that every session in it opens for a user or a group. Child
sessions follow their parent's share. You stay the owner either way: settings, lifecycle and
sharing remain yours.

**Edition:** Enterprise · **Who:** the session or project owner shares; recipients act as
**Viewer** or **Collaborator**

## Licence required

Sharing needs an active Enterprise licence. Without one:

- The **Share** dialog shows an *Enterprise feature* card ("Sharing sessions with other users
  needs an active enterprise license."). Admins get an **Activate a license →** link; everyone
  else is asked to contact an administrator. The project dialog shows the same card.
- The API answers sharing calls with **402** and the MCP tools fail with `license_required`.
- Existing shares stay stored but open nothing. Recipients no longer see the sessions, and share
  links show the invalid-link message. Once a licence is active again, the shares work again.

## Roles: Viewer and Collaborator

| | Viewer | Collaborator | Owner |
| --- | --- | --- | --- |
| Watch the terminal and the Workspace conversation, read the transcript | ✓ | ✓ | ✓ |
| See the workspace diff and the integrated browser | ✓ | ✓ | ✓ |
| List, preview and download session files | ✓ | ✓ | ✓ |
| Type in the terminal and composer, resize the terminal | — | ✓ | ✓ |
| Answer the agent's questions and CLI menus | — | ✓ | ✓ |
| Control the integrated browser, use its clipboard | — | ✓ | ✓ |
| Upload files, paste attachments, delete ready files | — | ✓ | ✓ |
| Tool approval prompts (**Allow** / **Deny**), secret requests, **Messages**, auto approve | — | — | ✓ |
| **Edit session**, shell, pause, resume, delete, duplicate, organize | — | — | ✓ |
| Manage sharing, the git identity and the MCP restrictions | — | — | ✓ |

A Viewer's session view is marked **Read-only**, and a Viewer's connection sends nothing to the
agent, not even terminal resizes. Only the uploader or the owner can cancel an unfinished
upload.

::: warning
Anyone who can type into a session can read whatever it holds, including the files in
`~/.secrets` and its secret environment variables. Give Collaborator only to people you would
hand the session's credentials to.
:::

## Share with a named user

Open the session and click **↗ Share** in its top bar, or the **↗** button on its row in the
sidebar. In the **Share session** dialog:

1. Type a name or username (at least two characters) or an exact email address. The dialog
   suggests up to 8 users who have signed in to this hub before. You are never suggested
   yourself, and email addresses are never displayed: an email only finds someone when typed
   in full.
2. Click a suggestion. The share always goes to the sign-in username.
3. Choose **Viewer** or **Collaborator** and click **Add**.

The person must have signed in at least once. Otherwise the dialog shows "No matching user…" and
the API answers `unknown_recipient`.

The recipient finds the session under **Shared with me** (see below) or opens it directly at
`https://hub.example.com/s/<session-id>`. If they are signed out, the sign-in brings them back to
that address. Signed in with the wrong account, they see "This session is unavailable or is not
shared with this account".

**For operators:** the suggestions reveal the names and usernames of everyone who has signed in.
To turn them off, set `sharing.userSuggestionsEnabled: false` in the chart (default `true`).
Owners then have to enter the exact username or email.

## Share links

Under **Share by link**, choose a role and, optionally, an expiry date, then click
**Create link**. The dialog shows the full link once ("Copy this one-time link now; it cannot
be shown again"). Anyone holding it opens the session at `/shared/<token>` with that role,
without signing in. Treat it like a password.

- Each link is listed by its id, where you can change its role or expiry (**Save**) or
  **Revoke** it. An expiry must be in the future.
- A link opens exactly that session, never its child sessions, and it never appears in anyone's
  session list.
- A link's files are read-only, even with the Collaborator role: no uploads, no deleting.
- An invalid, expired or revoked link shows the same message: "This share link is invalid,
  expired, or revoked. Ask the session owner for a new link."

**For operators:** links are built from the chart value `frontendOrigin`, which defaults to
`https://` plus `ingress.host`. Behind a proxy, set it to the public address. The hub must be
served at the root of its origin; a path prefix is not supported.

## Changing a role and revoking access

In the dialog, each person has a role selector with **Viewer**, **Collaborator** and
**Remove**. Changes apply on the recipient's next request; their list drops the session within
a few seconds. A terminal connection the recipient already has open stays open until it
reconnects.

## Child sessions inherit the share

When a shared session's agent starts child sessions, everyone who can open the parent opens the
children with the same role. Nothing is copied: revoking the parent's share closes the children
too, and a share added later reaches children that already exist.

When several grants reach a session, the strongest applies: Collaborator beats Viewer. A grant
only ever adds access, so a Viewer share on a child does not narrow a Collaborator share on its
parent. To take access away, remove the grant that gives it.

## Share a whole project

In the sidebar, hover over a project's header and click **⇪** (*Share project*). Share with a
**User** or a **Group**, as Viewer or Collaborator:

- The share opens every session of yours in the project, including sessions created later and
  their child sessions, even children outside the project.
- **Group** offers only identity-provider groups you belong to. Recipients' group membership is
  updated each time they sign in.
- A share on a single session adds to the project share, never reduces it. To keep someone out
  of one session, move it out of the project.
- Removing a project share, moving a session out of the project or deleting the project closes
  access on the next request. The session's own **Share** dialog lists the project's shares
  read-only, marked "via project".

Project shares are managed only in the web app. Personal API tokens and the MCP tools cannot
create or change them, but recipients can still reach the sessions through both.

Not tested: group shares with a real OIDC provider. Group membership was simulated in testing.

## "Shared with me"

Sessions shared with you, directly or through a project, appear in the sidebar and on the
**Sessions** page in the group **Shared with me**. Child sessions are nested under their parent
("child of …"). Each row shows your role, the owner ("by …") and, where it applies, "via project
…". The list updates every five seconds.

Status filters such as **Question open** and **Waiting** find shared sessions for every role.
**Needs you** on Home and the **SESSIONS** badge count a shared session only if you are
Collaborator, because a Viewer cannot answer.

## MCP restrictions for the whole session

Under **MCP security** in the **Share** dialog, you can block MCP servers (one name per line) or
exact tool names such as `mcp__server__tool`, then click **Save MCP policy**. The block applies to
everyone who works in the session, including you, from the next MCP call on. It also covers
child sessions, and it is a hard deny even with auto approve on. Tool results already in the
transcript stay there.

The block is enforced for Claude, Codex and OpenCode sessions, which check every tool call with
the hub. Cursor and OpenClaw sessions have no such check, so the block does not reach them. (Read from the
code; not tested in a running Cursor or OpenClaw session.)

## Managing shares from an API client

With a personal API token (`Authorization: Bearer oah_…`) you can manage shares of your own
sessions:

| Method and path | Purpose |
| --- | --- |
| `GET /api/remote/sessions/shared` | Sessions shared with you |
| `GET /api/remote/sessions/{id}/shares` | People and links (never the link tokens) |
| `POST /api/remote/sessions/{id}/shares/users` | `{ "recipient", "role" }`: share, or change the role |
| `DELETE /api/remote/sessions/{id}/shares/users/{recipient}` | Revoke a person |
| `POST /api/remote/sessions/{id}/shares/links` | `{ "role", "expiresAt" }`: returns an absolute `url`, once |
| `DELETE /api/remote/sessions/{id}/shares/links/{linkId}` | Revoke a link |

The AgentHub MCP server (stdio and remote, see [MCP clients](/mcp)) offers the same as tools:
`session_share`, `session_unshare`, `session_share_link` and `session_shares`. Roles are
`Viewer` (the default) or `Collaborator`. A misspelt role fails with `invalid_role` instead of
being guessed. To revoke a link, use the DELETE route above or the dialog. An agent cannot share
its own session: the MCP server inside a session pod has no sharing tools. For how a session's
agent can reach sessions shared with its owner, see Session tools.

## When a session is deleted

Deleting a session removes its shares, links and MCP restrictions with it. Its links then
return 404 and show the invalid-link message, and the session disappears from recipients'
lists. Child sessions you keep lose the access they inherited from the deleted parent.

## History of a shared session

Everyone a session is shared with can read its whole conversation, not only what is still in the
terminal. That covers people you shared it with by name, children of a shared session, sessions
shared through a project, and share links — as Viewer or as Collaborator.

- Open the **Workspace** view of the shared session. It shows the newest messages first; use
  **Load earlier messages** to go back to the start of the conversation.
- While the session runs, the conversation follows the agent live, as it does for the owner.
- The history comes in pages of up to 500 messages, so a long session loads a page at a time.
- Values only the owner may see are shown as `[redacted]`. Session secrets are hidden the same
  way they are for the owner.
- Revoking a share, deleting a link or letting it expire takes effect on the next request. An open
  shared page then shows *This share link is invalid, expired, or revoked*.

The same history is available to MCP clients that read a session shared with you.
