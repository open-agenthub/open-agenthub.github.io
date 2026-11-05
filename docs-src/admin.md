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
| 4 | Nobody is designated as admin by any rule above | admin (bootstrap) | Ends as soon as one admin is designated |
| 5 | Membership in a group mapped to **user** (Enterprise) | user | Label only |
| 6 | Otherwise | user | — |

- **Bootstrap:** on a fresh install with no admin designated, every signed-in user is an admin.
  The roles card says so. Making someone an admin ends bootstrap for everyone else.
- **API key:** on an install without OIDC, the user the API key acts as is always an admin.
- **`ee.admins`** takes comma-separated usernames (the `preferred_username` claim). These accounts
  cannot be demoted in the UI, so they still work if the role settings are edited into a corner.
  Listed admins who have not signed in yet are shown too.
- **A per-user role wins over groups.** You can demote one member of an admin group, or promote
  one person without creating a group for them.
- **Admin wins over user within groups.** Someone in both an admin group and a user group is an
  admin. A **user** mapping only labels; it never restricts who can sign in.
- **The last admin cannot be removed**, yourself included. Falling back into bootstrap counts as
  removing the last admin.

Role changes apply at the user's next request on every backend replica, without a redeploy. Roles
can be set only for users who have signed in at least once. **Recent role changes** shows who changed
what, and when.

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
Only an aggregate user count is sent. **Last check-in** shows the most recent report.

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
