# Pilot setup

This page takes a pilot team from an empty host to a running instance with team login and,
if your pilot includes it, an active Enterprise licence. It collects the steps in the order
that avoids the known traps; the linked pages hold the details.

**Edition:** Community (install, team login, admins) · Enterprise (licence and the features it
unlocks) · **Who:** the operator who installs the chart and the first administrator

Placeholders in capitals, such as `YOUR_HOST` or `YOUR_USERNAME`, stand for your own values.

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

An administrator opens **Settings → License**. There are two ways to a token:

| Way | What happens |
|---|---|
| **Issued to you** | For a pilot or a contract with manual invoicing, the licence is issued for your organisation and the token is sent to you. Paste it into **License token** and click **Activate**. |
| **Checkout** | **Get enterprise license** asks for billing email, organisation and seats and redirects to the payment provider. Afterwards the instance comes back to `https://YOUR_HOST/license/activate` and activates the licence itself. If that return did not happen, **Retrieve license** with the same billing email activates a licence that has been paid but not yet activated. The checkout page shows the price and terms that apply before you pay. |

Only an administrator sees **Settings → License**.

### Licence status

After activation the **Enterprise license** card shows:

- a badge: **active**, **invalid** (a token is stored but does not verify or has expired) or
  **not activated**;
- **Plan**, **Organization** and **Seats included**;
- **Valid until** for a licence with a fixed end, otherwise **Renewal: automatic**;
- **Last successful report**, **Enterprise features stop without renewal** and **Last report
  error**.

The instance renews its token by reporting to the licence service, normally once every 24 hours.
The report contains the token and an aggregate count of licensed users, nothing else. The backend
needs outbound HTTPS to the licence service for this (chart value `ee.license.serviceUrl`; an empty
value disables reporting). If renewal keeps failing, Enterprise features stop at the date shown on
the card; Community features keep working. An admin warning appears seven days before that date.
See [Check renewal health](/admin#check-renewal-health).

Every user who signs in gets a seat. **Settings → Users & seats** shows the seats in use against
the seats included; untick a user to free a seat.

### Manual invoicing

If your organisation does not pay through the online checkout, the licence is issued to you
and you are invoiced separately.

::: info Terms: per your order form
Invoicing interval, payment terms, seat count, how seat changes are invoiced, and the licence
term are set by your order form. This page does not describe them.
:::

With manual invoicing, **Settings → Billing & invoices** may not apply to you: invoices come
the way your order form says. The seat count the instance reports is visible under
**Settings → Users & seats**.

## 4. Before the team starts

- **Back up** the database and the Secret `agenthub-data-protection` from the first day; the
  stored secrets cannot be decrypted without that Secret. See
  [Before every upgrade](/upgrading#before-every-upgrade) for the commands.
- **Leave experimental features off.** `agent.workspaceVolume.persistent` (the provider switch)
  stays `false`, the chart default.
- **Agree how you will upgrade.** Read [Upgrading](/upgrading) and plan the first upgrade before
  you need it.
- **Know where to get help.** See [Support](/support).
