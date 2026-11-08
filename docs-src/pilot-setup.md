# Pilot setup

This page takes a pilot team from an empty host to a running instance with team login and,
if your pilot includes it, an active Enterprise licence. It collects the steps in the order
that avoids the known traps; the linked pages hold the details.

**Edition:** Community (install, team login, admins) · Enterprise (licence and the features it
unlocks) · **Who:** the operator who installs the chart and the first administrator

Placeholders in capitals, such as `YOUR_HOST` or `YOUR_USERNAME`, stand for your own values.

## Who operates what

Open AgentHub is self-hosted: you run it on your own infrastructure, and we operate nothing for
you. We have no access to your systems, accounts, credentials, logs, prompts or files, and we
record nothing.

| You run and are responsible for | Notes |
|---|---|
| Kubernetes, ingress, DNS and TLS certificates | The quickstart can set up a single-node cluster for you |
| Postgres and S3-compatible object storage, and their backups | See [Before every upgrade](/upgrading#before-every-upgrade) |
| Your identity provider (OIDC) | See [Team login](#_2-team-login-oidc) |
| Network security, including egress from the instance | |
| The agents' provider accounts: your own subscriptions or API keys | See [Provider login](/provider-login) |
| Upgrades, with `helm upgrade --version` | See [Upgrading](/upgrading) |

What we provide is the software, the Enterprise licence and, for Enterprise customers, the
support and onboarding described on [Support](/support).

## 1. Install

Pick one of the two paths on [Install](/getting-started). Both install the current release.

| Path | When | Command |
|---|---|---|
| Quickstart | One Linux host, or Docker Desktop on macOS or Windows, without an existing cluster | `curl -fsSL https://open-agenthub.github.io/install.sh \| sh` (Windows: `install.ps1`) |
| Helm | You already run Kubernetes | `helm repo add agenthub https://open-agenthub.github.io/open-agenthub`, then `helm install` as shown on [Install](/getting-started#you-have-a-kubernetes-cluster) |

The quickstart sets up persistent Postgres and object storage for you. With Helm, configure
object storage as well (`s3.*`, or `objectStorage.enabled=true`): without it, sessions cannot
resume in a fresh pod and uploaded files disappear with the pod.

For a pilot that may run longer than a test, prefer your own Postgres
(`postgres.enabled=false` and `externalDatabase.connectionString`); the bundled one is meant for
evaluation. Keep all settings in one values file from the start, such as `my-values.yaml`, and
pass it to every `helm upgrade` with `-f`. That file holds secrets: keep it out of version
control.

The [evaluation checklist](/evaluate) lists what to prepare (hostname, TLS certificate,
identity provider, Git access, a model account) and how long each step took when we measured it.

## 2. Team login (OIDC)

Without an identity provider the instance runs with one generated API key that acts as an
administrator. For a team, switch to OIDC. Do it in this order:

1. **Choose the first administrator.** Under OIDC nobody is an administrator until one is
   named. Use that person's sign-in name as your identity provider issues it in the
   `preferred_username` claim.
2. **Register the client** at your identity provider: a public client with Authorization Code
   Flow and PKCE, redirect URI `https://YOUR_HOST/auth/callback`, post-logout redirect
   `https://YOUR_HOST`, web origin `https://YOUR_HOST`, JWT access tokens for your audience,
   and refresh tokens (`offline_access`). [Install → Sign in](/getting-started#_2-sign-in)
   lists every requirement.
3. **Set the administrator and the OIDC values in the same upgrade**, so there is no moment
   in which the instance has team login but no administrator:

   ```yaml
   # my-values.yaml (excerpt)
   ingress:
     enabled: true
     host: YOUR_HOST
     tlsSecretName: YOUR_TLS_SECRET
   frontendOrigin: https://YOUR_HOST
   oidc:
     authority: https://YOUR_ISSUER
     clientId: agenthub
     audience: agenthub
   ee:
     admins: "YOUR_USERNAME"
   ```

   ```bash
   helm upgrade agenthub agenthub/open-agenthub -n agenthub -f my-values.yaml --wait --timeout 5m
   ```

4. **Sign in as that administrator first**, before you share the URL. Then promote further
   administrators under **Settings → Users & seats → Admins & roles**.

`ee.admins` takes comma-separated names. Names listed there cannot be demoted in the app, so they
remain a way back in if role settings go wrong. Despite the `ee.` prefix, the value works in
both editions. Groups from your identity provider can grant the admin role only with an
Enterprise licence; keep at least one name in `ee.admins` as a fallback.

Data created while the API key was in use belongs to the key's user name and becomes visible to
an OIDC user with the same name. Read
[Switching from the API key to OIDC](/admin#switching-from-the-api-key-to-oidc) before you switch.
If your identity provider uses a certificate from an internal certificate authority, see
[team login](/getting-started#move-the-quickstart-to-team-login) for `backend.trustedCaConfigMap`.

## 3. Enterprise licence

**Enterprise.** The Community edition is fully usable without a licence. A licence unlocks the
Enterprise features: sharing, group roles, usage limits, the agent allowlist, Slack and the
others marked Enterprise in the [feature overview](/features).

The licence is a signed token. The instance verifies it offline and stores it in its database.
No chart value switches Enterprise features on.

### How an instance gets a licence

An administrator activates the licence under **Settings → License**. Which way applies depends on
how you buy.

**If you have an order form, your licence is issued to you; do not use the online checkout,
which starts a trial for new billing addresses.**

| You buy | How the token reaches the instance |
|---|---|
| **With an order form** (invoice subscription or a licence issued by us) | Either we hand the token to you: paste it into **License token** and click **Activate**. Or you retrieve it yourself: click **Get enterprise license**, enter only the **Billing email** from your order form, and click **Retrieve license**, not **Continue to checkout**. |
| **Self-service checkout** | **Get enterprise license** asks for billing email, organisation and seats and redirects to the payment provider; the instance then activates the licence itself. It starts a trial for new billing addresses and is not the path for customers with an order form. |

The licence can be active before the first invoice is paid. Only an administrator sees
**Settings → License**.

::: warning DRAFT: payment and term details
How invoices, payment and the licence term relate is set by your order form. The order form
these pages refer to is still a draft and not approved; your signed order form applies.
:::

### Licence status

After activation the **Enterprise license** card shows:

- a badge: **active**, **invalid** (a token is stored but does not verify or has expired) or
  **not activated**;
- **Plan**, **Organization** and **Seats included**;
- **Valid until** for a licence with a fixed end, otherwise **Renewal: automatic**;
- **Last successful report**, **Enterprise features stop without renewal** and **Last report
  error**.

### Daily report and renewal

About 30 seconds after the backend starts, and then once every 24 hours, the instance reports to
the licence service. The report contains the licence token, the number of seats in use and a
random key that identifies the instance; no user names, prompts or content. The answer is a
renewed token, currently valid for 45 days. The card shows the exact date as **Enterprise features
stop without renewal**.

- **Without a successful report**, the Enterprise features stop at that date. The Community
  edition keeps running, with all its features and your data.
- **The backend needs outbound HTTPS** to the licence service (chart value
  `ee.license.serviceUrl`). The chart sets no egress policy for the backend namespace; your own
  firewall, proxy or network policy must allow it. An empty value disables reporting, and the
  licence then stops at the token's date.
- **One licence per instance.** Use each licence on one instance; ask support before moving it.

### When the licence warning shows or reporting fails

By default the card warns seven days before the stop date (`ee.license.reportWarningDays`):
*Enterprise features stop at … unless the license renews.* Check **Last report error**:

| Last report error | What it means | What to do |
|---|---|---|
| `License service request failed. Check connectivity and service availability.` | The backend could not reach the licence service | Check DNS, firewall, proxy and egress from the backend pods to the host in `ee.license.serviceUrl` |
| `License service rejected the report (HTTP 403).` | The subscription is no longer active | Check your contract or subscription; contact support |
| `License service rejected the report (HTTP 409).` | The licence service refused the report for this instance | Contact support with the error and the stop date |
| `License service rejected the report (HTTP 401).` | The token expired too long ago | Contact support for a new token |
| `License token has no license id. Re-activate it to enable reporting.` | An old token without metering | Activate the token again, or ask support for a current one |

Then:

1. Note the date under **Enterprise features stop without renewal**: that is how much time is left.
2. After fixing connectivity, restart the backend to report at once instead of at the next
   scheduled time: `kubectl -n agenthub rollout restart deployment/agenthub-backend`. About 30
   seconds after the start, **Refresh license status** shows the result.
3. If the error stays, or the stop date is close, contact [support](/support) with the error text
   and the date. Do not send the licence token.

The backend log shows the same events (`Seat usage report failed.`, `Seat report rejected`).
More on the card: [Check renewal health](/admin#check-renewal-health).

### Seats

A seat is a user who has signed in at least once and whose seat an administrator has not revoked.
With a licence, every user gets a seat on sign-in. **Settings → Users & seats** shows the seats in
use against the seats included; untick a user to revoke the seat. Revoke the seats of people who
no longer use the instance, since the reported count is the number of seats in use.

### Manual invoicing

If your organisation does not pay through the self-service checkout, the licence comes with your
order form and you are invoiced separately.

::: info Terms: per your order form
Invoicing interval, payment terms, seat count, how seat changes are invoiced, and the licence
term are set by your order form. This page does not describe them.
:::

With manual invoicing, **Settings → Billing & invoices** may not apply to you: invoices come
the way your order form says.

## 4. Before the team starts

- **Back up** the database and the Secret `agenthub-data-protection` from the first day; the
  stored secrets cannot be decrypted without that Secret. See
  [Before every upgrade](/upgrading#before-every-upgrade) for the commands.
- **Leave experimental features off.** `agent.workspaceVolume.persistent` (the provider switch)
  stays `false`, the chart default.
- **Agree how you will upgrade.** Read [Upgrading](/upgrading) and plan the first upgrade before
  you need it.
- **Enterprise: plan the onboarding sessions** within the first 30 days; see
  [Onboarding](/support#onboarding).
- **Know where to get help.** See [Support](/support).
