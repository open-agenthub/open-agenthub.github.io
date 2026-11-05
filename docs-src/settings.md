# Settings

**Settings** holds everything that belongs to your own account: profile, interface preference,
credentials, secrets, MCP servers, skills, notifications, API tokens and webhook triggers. This page
is a reference for the **PERSONAL** tabs; most link to a page of their own. Admins also see an
**ADMIN** section, described in [Administration](/admin).

**Edition:** Community (Slack notifications: Enterprise) · **Who:** every signed-in user

Each tab has its own address, such as `https://hub.example.com/settings/tokens`, so you can
bookmark or share a link to it.

## Profile

Your display name, email and the username you are **Signed in as**, with **Sign out**. **About**
shows the running Open AgentHub version, with links to the source and the documentation.

### Deleting your account

The **Danger zone** deletes your account and **all** of its data permanently:

- your sessions, with their pods, browsers, files and stored state,
- credentials, provider logins and git connections,
- skills, MCP servers, usage history and chat links.

Type your username to confirm, then click **Delete account permanently**. This cannot be undone.
Your identity at your OIDC provider is not affected: signing in again starts an empty account.

## Interface

Choose the **Preferred interface** for your sessions and the new-session dialog:

- **Workspace**: conversation, tasks and tools in one view (the default). See [Workspace](/workspace).
- **Terminal**: the agent's own console interface.

Click **Save preference**. The choice is stored in this browser only, so another browser or device
starts with Workspace again.

## Connected accounts

Connect your GitHub or GitLab account, so sessions can clone and push without a personal access
token. The tab only appears when the operator has configured a git provider. See [Git](/git).

## Credentials

Provider logins and API keys for the agents, git tokens and your SSH key. Values are write-only:
the page only shows whether something is stored. See [Provider login](/provider-login) and [Git](/git).

## Secrets, MCP servers and Skills

- **Secrets**: named values delivered into sessions as files or environment variables. See
  [Secrets](/secrets).
- **MCP servers**: your personal library of MCP servers for sessions. See [MCP servers](/mcp-servers).
- **Skills**: your skill library. See [Skills](/skills).

## Notifications

| Section | Shown when | What it does |
| --- | --- | --- |
| **Desktop notifications** | Always | Your browser notifies you when a session waits or finishes while the tab is in the background. No server setup needed. |
| **Telegram notifications** | Telegram is enabled on the instance | Link your Telegram account or a forum group with a link code, then get session updates and reply from Telegram. See [Chat](/chat). |
| **Signal notifications** | Signal is enabled on the instance | Enter your phone number and verify it with a one-time code. See [Chat](/chat). |
| **Slack notifications** | Slack is enabled (Enterprise) | A Slack thread when a session waits for input, answered from Slack. By default sent to you directly; a channel can be set instead. See [Slack](/slack). |

If no chat integration is enabled, the tab says so.

## API tokens

Personal API tokens let scripts and tools start sessions and check their status without the web
app, through the remote API (`/api/remote/...`) or the [stdio MCP server](/mcp). A token starts with
`oah_` and **acts as you**.

1. Enter a **Token name** (for example `ci-runner`) and click **Create token**.
2. Copy the token right away. It is shown only once.

The list shows each token's name, prefix, restriction, and when it was created and last used.
**Delete** asks once more, then stops every client that uses the token. Tokens do not expire;
delete the ones you no longer need. **Using a token from the command line** shows example `curl`
calls and an MCP client snippet.

### Restricting a token

Tick **Restrict to credentials** when creating a token, or click **Restrict** on an existing one.
Then tick what sessions created with the token may use:

- provider logins, per agent,
- git tokens,
- secrets delivered into those sessions,
- **API keys**: sessions billed to a stored API key.

Anything left unticked is not available. If nothing is ticked, the token cannot create sessions at
all. A session that asks for something outside the restriction is refused. The restriction only
governs what a token can bring into a new session. The token can still read, pause and delete your
sessions like you can.

## Webhooks

A webhook trigger starts an **autonomous session** whenever GitHub or GitLab sends a pull request or
merge request event, for example a review session for every new merge request.

1. Under **New webhook trigger**, fill in:
   - **Name**.
   - **Git account for cloning** (optional, shown when git providers are configured). Leave empty
     for public repositories.
   - **Events**: `opened` and `reopened` by default; also `updated`, `closed`, `merged`.
   - **Repository filter** (optional): part of `group/repo`. Other repositories are ignored.
   - **Prompt template**: the session's prompt. The placeholders below are filled from the event.
   - **Agent**, and whether to **Auto-approve tool permissions**. See [Auto approve](/auto-approve).

   ```text
   {{title}}  {{description}}  {{source_branch}}  {{target_branch}}
   {{url}}  {{repo}}  {{id}}  {{action}}
   ```

2. Click **Create webhook**, then copy the URL and the secret. The secret is shown only once; if you
   lose it, delete the trigger and create a new one.
3. Register the webhook in the repository:
   - **GitLab**: **Settings → Webhooks**, the URL, the secret as **Secret token**, and
     **Merge request events** only.
   - **GitHub**: **Settings → Webhooks**, the URL as **Payload URL**, content type
     `application/json`, the secret, and the **Pull requests** event only.

The session checks out the source branch and runs the rendered prompt under your account. Repeated
deliveries of the same event are ignored for a few minutes. Other events, other repositories and
deliveries that cannot start a session (for example at your session limit or budget) are
acknowledged without retry. Each trigger in the list shows when it was **last triggered**.

This tab only covers incoming triggers. Settings has no outgoing notification webhooks.
