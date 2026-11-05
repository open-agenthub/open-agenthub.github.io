# MCP servers for sessions

You can give a session extra tools by attaching MCP servers. Save a server once in your
library and pick it for any session, or write an MCP config for one session only. You can
also point the hub at an OpenAPI or GraphQL API, and it turns that API into an MCP server.
Admins can keep an organisation-wide catalog. With the Enterprise Edition, users can share
their entries with other users and groups.

**Edition:** Community. Sharing entries with users and groups is Enterprise. · **Who:**
session owner. The org catalog needs an admin.

This page covers MCP servers the agent uses *inside* a session. To drive the hub from an
MCP client on your own machine, see [MCP for external clients](/mcp). For the tools every
session already has, see [Built-in tools inside a session](/session-tools).

## Your library: Settings → MCP servers

Open **Settings → MCP servers** and click **Add MCP server**. Give the entry a **Name** and,
if you like, a **Description**, then pick one of two tabs:

| Tab | What you enter | What the session gets |
| --- | --- | --- |
| **From API URL** | **Spec URL** of an OpenAPI or GraphQL API, **Spec type** (`auto`, `openapi`, `graphql`), an optional **Base URL** and an optional **Secret** (a token, or a JSON object) | An MCP server run by the hub, with one tool for each API operation, or each GraphQL query and mutation |
| **Raw MCP config** | One server entry as a JSON object, for example `{ "type": "http", "url": "https://mcp.example.com/mcp" }`. Not a whole `.mcp.json`. | That entry, copied unchanged into the session's MCP config |

A raw entry can describe any server the agent's CLI understands: a remote HTTP server with a
`url` and `headers`, or a local stdio server with `command`, `args` and `env`. A stdio server
runs inside the session pod, so the program has to exist in the session image.

The list shows each entry's kind (`api` or `raw`), a **has secret** tag when it has a stored
secret, and **shared ·** and the owner's name for entries other users shared with you. You can edit and
delete only your own entries. Shared entries are read-only, and you cannot see their
configuration. Deleting an entry does not affect sessions that already use it.

## Attaching servers to a session

In the new-session dialog, open **Advanced**:

- **Saved MCP servers — from your library**: tick the entries this session should get. Each
  one has a tag: **Mine**, **Org** or **Shared**. The list appears only when your library
  has entries.
- **API URL — OpenAPI/GraphQL for this session**: an API for this session only. Tick
  **Save to my library** to keep it as an entry too.
- **Extra tools — MCP servers the agent can use (.mcp.json)**: a full `.mcp.json` with an
  `mcpServers` object, for servers you want in this one session only.

The hub merges all three into the session's MCP config. When a name appears twice, the
inline `.mcp.json` entry wins over a library entry. That way you can override a saved
definition for one session.

Child sessions an agent starts get the same servers as their parent, unless the agent names
others. A server that was deleted or unshared in the meantime is left out. See
[Built-in tools inside a session](/session-tools).

## How credentials are handled

The two kinds of entry handle credentials very differently:

- **From API URL**: the **Secret** is stored encrypted and stays in the hub. The session gets
  only the hub's address and a token bound to this session. The agent never sees the API
  secret.
- **Raw MCP config** and **Extra tools**: every value is copied as written into a file the
  agent can read. That includes header values such as `Authorization` and `env` values.
  The agent can read a token you put there, and so can any code it runs.

::: warning
Treat a literal token in a raw config as handed to the agent. If you share a raw entry with
other users, their sessions get the token too. Prefer **From API URL** for an API with a
secret. Otherwise use a token with narrow permissions that you can revoke.
:::

## Org MCP catalog (admins)

Admins manage organisation-wide entries under **Settings → Org MCP catalog**, with the same
form as the personal library. Who can use them:

- **Without an Enterprise licence**: every signed-in user, in the new-session dialog,
  tagged **Org**.
- **With an Enterprise licence**: whoever the admin shares each entry with, using the entry's
  **Sharing** control: everyone, specific users, or groups from your OIDC provider.

## Sharing your entries (Enterprise)

With an active licence, each of your own entries has a **Sharing ▸** button. Choose
**Share with everyone**, pick **Users**, or tick **Groups**, then click **Save sharing**.
Recipients see the entry as **shared ·** with your name and can attach it to their sessions.
They cannot see or change its configuration. Without a licence, the control explains that
sharing needs the Enterprise Edition. Entries shared with you stop appearing when the
licence lapses or the share is removed.

## Restricting MCP tools in a session

Two settings narrow what a session may call:

- For autonomous and scheduled sessions, the new-session **Advanced** section has **Full MCP
  tool names and patterns**, an allow list such as `mcp__docs__search` or `mcp__git__*`.
  Whether a tool outside the list is denied or asked about depends on auto-approve. See
  [Auto approve](/auto-approve).
- With the Enterprise Edition, owners can block servers or exact tools for everyone in a
  shared session, including themselves. This is a hard deny. See [Sharing](/sharing).
