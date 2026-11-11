# Administration

Admins manage users and roles, the organisation's MCP catalog, the Enterprise licence and, with a
licence, usage limits, group roles, allowed agents and skill publishing. All of it lives in the
**ADMIN** section of **Settings**, which only admins see.

**Edition:** Community (admin roles, Org MCP catalog, licence entry) · Enterprise (seats, usage
limits, group roles, allowed agents, skill publishing, billing) · **Who:** admin, operator

## Who is an admin

The first matching rule decides:

| # | Source | Result | Changeable in the UI |
| --- | --- | --- | --- |
| 1 | The username is listed in the chart value `ee.admins` | admin | No: a break-glass admin |
| 2 | A role set for the user under **Users & seats → Admins & roles** | admin or user | Yes |
| 3 | Membership in an OIDC group mapped to **admin** (Enterprise) | admin | Yes, under **Usage limits & groups** |
| 4 | Membership in a group mapped to **user** (Enterprise) | user | Label only |
| 5 | Otherwise | user | — |

- **Nobody is an admin by default.** With OIDC, name the first admin in the chart value
  `ee.admins` (see below); after that, admins can promote others in the UI. Until then nobody can
  open the admin area, and every signed-in user sees a notice: *No administrator is designated*,
  with the value to set for their own username. `helm install` and `helm upgrade` print the same
  hint, and the backend logs it at startup.
- **API key:** on an install without OIDC, the user the API key acts as is always an admin.
- **`ee.admins`** takes comma-separated usernames (the `preferred_username` claim). These accounts
  cannot be demoted in the UI, so they still work if the role settings are edited into a corner.
  Listed admins who have not signed in yet are shown too.
- **A per-user role wins over groups.** You can demote one member of an admin group, or promote
  one person without creating a group for them.
- **Admin wins over user within groups.** Someone in both an admin group and a user group is an
  admin. A **user** mapping only labels; it never restricts who can sign in.
- **The last admin cannot be removed**, yourself included.

Role changes apply at the user's next request on every backend replica, without a redeploy. Roles
can be set only for users who have signed in at least once. **Recent role changes** shows who changed
what, and when.

### Designating the first admin

Set your OIDC username (the `preferred_username` claim) and upgrade the release:

```bash
helm upgrade agenthub agenthub/open-agenthub -n agenthub --reset-then-reuse-values \
  --set-string ee.admins=alice
```

Several names are comma-separated. Accounts listed there stay admins whatever is set in the UI.

**Upgrading from 1.18 or earlier:** older releases made every signed-in user an admin while no
admin was designated. That no longer happens. Admins you designated in `ee.admins`, under
**Admins & roles**, or through an admin group keep their rights. If you never designated one,
nobody is an admin after the upgrade until you set `ee.admins`.

### Switching from the API key to OIDC

Data belongs to a username. Everything created with the API key — sessions, credentials,
projects — belongs to the key's user (`admin` unless you set `auth.apiKey.owner`; `dev` on
installs from before the API key). After a switch to OIDC, that data is visible to the
identity-provider user with the same username.

**Before you switch**, do one of these:

- Choose a key user name that nobody can register at your identity provider
  (`auth.apiKey.owner`) — ideally when you install, before any data exists.
- Or move or delete the data that should not carry over.

After the switch:

- Set `ee.admins` to your OIDC username. The key's user name does not make anyone an admin under
  OIDC: it can only be made one through `ee.admins`, not under **Admins & roles** or through a
  group.
- While data is still stored under that name, admins see a notice — *Data from API-key mode is
  under the name …* — with the number of sessions and projects, and the backend logs it at
  startup.
- With a licence, the key's user keeps a seat under **Users & seats**. Revoke it there once you no
  longer need its data.
- Hand the data to the person it belongs to, as below.

### Hand over data from API-key mode

After the switch, an admin moves what was created with the API key to one chosen team-login
user: **Settings → Users & seats → Hand over data from API-key mode**. Nothing moves by itself,
and nothing moves because a username happens to match.

1. The target user signs in once, so they appear in the list.
2. Pause the sessions of the key's user that are still running. The preview names them; a
   running session blocks the handover.
3. Choose **From** (the key's user, e.g. `admin`, or `dev` on older installs) and **To**, then
   **Preview**. The preview lists, per kind, what moves: sessions, projects, skills, MCP servers,
   webhook triggers, session files, usage history, open requests and shares, plus how many objects
   and how much stored session data are copied.
4. **Hand over to …** applies exactly what the preview showed. If anything changed in between,
   preview again. Earlier handovers are listed under **Handovers**.

What you should know:

- **Stored credentials move only if you tick _Also hand over stored credentials_.** That covers
  provider logins and API keys, Git access tokens, connected Git providers, stored secrets, the
  SSH key and Git name/e-mail. The target user can then use them, for example someone else's model
  subscription or Git access, so tick it only if they belong to that person. Without the tick they
  stay with the key's user, and a moved session that needs them asks for a new sign-in or secret
  when it starts. Values are never shown, only which kinds exist.
- **The target's own data wins.** Their API keys, logins and defaults stay as they are. A
  project, skill or MCP server whose name they already use gets a suffix (` (API key)` or
  `-api-key`); the preview lists each rename.
- **Scheduled sessions** keep their schedule. It is paused during the handover and set up again
  for the new owner.
- **What stays with the key's user:** personal API tokens (revoke them if nobody needs them),
  the seat under **Users & seats**, roles and a usage limit set for that name. Slack, Telegram and
  Signal threads of moved sessions end; the next question opens a thread in the new owner's chat.
- **Only admins** can hand over data, in both editions, and only on an install that uses OIDC.

## Admin tabs in Settings

| Tab | What it contains | Edition |
| --- | --- | --- |
| **Users & seats** | Everyone who has signed in. With a licence, each user's seat (**licensed** / **no seat**) and the seat count; the **Admins & roles** card with role, source and change history. | Roles: Community. Seats: Enterprise |
| **Org MCP catalog** | MCP servers offered to the whole organisation. See [MCP servers](/mcp-servers). | Community |
| **Usage limits & groups** | Organisation-wide API budgets, OIDC groups and their roles, allowed agents. | Enterprise |
| **Skill publishing** | **User skill publishing**: whether non-admin users may publish their own skills to everyone. See [Skills](/skills). | Enterprise |
| **Billing & invoices** | A link to the billing portal for subscription, invoices and cancellation. | Enterprise |
| **License** | Enter, view and remove the Enterprise licence. | Community |

Without a licence, an Enterprise pane shows **Enterprise feature** with a link to activate one.

## Entering a licence

1. Open **Settings → License**.
2. Paste the token into **License token** and click **Activate**.
3. The card shows plan, organisation, seats included and renewal or end date.

The licence is verified offline and stored in the database, not in the chart, so no Helm value
can switch Enterprise features on. Without a licence, every admin tab offers
**Get enterprise license**, which opens a checkout for billing email, organisation and seats, and
**Retrieve license** for a licence already paid but not yet activated.

With a licence, every user who signs in gets a seat automatically; untick it to free the seat.
The instance reports its seat count to the licence service, which also renews the licence token.
Only an aggregate user count is sent. **Last check-in** shows the most recent successful report.

### Check renewal health

Open **Settings → License** as an admin. For an activated licence the card shows:

- **Last successful report**, or **never** before the first successful renewal.
- **Enterprise features stop without renewal**, the expiry of the currently verified token.
- **Last report error**, with its timestamp, or **none**. Errors remain visible across backend
  restarts and are cleared when a renewal succeeds.

A warning appears seven days before the token expires and remains after expiry. Operators can
change the lead time with `ee.license.reportWarningDays` (0–365, default 7). Zero warns only at
expiry. This setting affects the warning, not licence validity or the reporting schedule.
Reporting normally runs every 24 hours (`ee.license.reportIntervalHours`), starting about 30
seconds after the backend starts. Opening the page or **Refresh license status** reloads the
status; the page does not send a report or continuously poll. No external notification is sent.

If reporting fails, restore backend connectivity to the licence service and check your
subscription under **Billing & invoices**. A rejected report shows its HTTP status; a request
failure means connectivity or service availability needs checking. Invalid or missing renewal
tokens leave the previous token in place. A successful renewal clears the error and moves the
stop date according to the new signed token. Restart the backend to retry before its next
scheduled report if needed.

The stop date is distinct from a scheduled cancellation or a plan end date: it is when
Enterprise features stop if no further renewal succeeds. It is read from the signed token,
not calculated as 45 days after the last report. Community features remain available after
expiry, and admins can still inspect and activate a licence without an Enterprise entitlement.

## Usage limits

Admins can set a monthly API budget for everyone (**Global limit**), for a group, or for a single
user. The strictest limit that applies wins, and personal limits still apply. Details are on
[Usage and cost](/usage#organisation-wide-limits).

## Groups from the OIDC token

With Enterprise, the hub reads each user's groups from the access token at sign-in. The claim is
`groups` by default. A leading `/` in a group path is dropped, so `/team/platform` is stored as
`team/platform`.

Under **Usage limits & groups → Groups & roles**, groups appear once a member has signed in. Map a
group to **admin** or **user**, or type a group name nobody has signed in with yet and click
**Map**. Its first member is then an admin from their first request. Groups are also used for
group limits, for project shares (see [Sharing](/sharing)) and for sharing skills and MCP servers.

Not tested: group membership was seeded in tests, not read from a real OIDC provider.

## Allowed agents

**Usage limits & groups → Allowed agents** restricts which agents (Claude, Codex, Cursor, OpenClaw,
OpenCode) can be used for new sessions. Leave every box unticked for no restriction. A session with
an agent that is not allowed is refused on create, edit, start, resume and duplicate, with a message to
ask an administrator. Without a valid licence, every agent is allowed.

## Operator settings

Some admin matters are chart values, not UI settings: `ee.admins`, `ee.billingPortalUrl`, and the
Slack integration (`ee.slack.*`). See [Chart values](/chart-values) and [Slack](/slack).
