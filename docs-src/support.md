# Support

What support covers, how to reach it, and how to report a problem without handing over
secrets.

**Edition:** Community (public issues) · Enterprise customers (email support and onboarding, per
the order form) · **Who:** operators and administrators of an instance

## Community edition

Report bugs and ask questions as
[GitHub issues](https://github.com/open-agenthub/open-agenthub/issues). Issues are public and
answered on a best-effort basis, without a response time. Do not post logs, values files or
screenshots that contain credentials, hostnames or user content there; see
[Reporting a problem](#reporting-a-problem).

Report suspected vulnerabilities privately to `open-agenthub@mail.on-mb.com`, never as a
public issue.

## Enterprise customers

Support does not access your systems, accounts or data; you run all commands yourself, also
during a screen share.

::: warning DRAFT: support terms
The terms in this section follow a draft order form that is not yet approved. Your signed order
form applies.
:::

### How to reach support

- **By email** to `SUPPORT_EMAIL`, on business days.
- **Acknowledgement of receipt:** planned in the contract within one business day. It confirms
  that your email arrived; it is not a deadline for an answer or a fix.
- **No service level:** there is no guaranteed availability, response time or resolution time,
  and no 24/7 support.

Support works from what you send. See [Who operates what](/pilot-setup#who-operates-what).

### Onboarding

Enterprise customers get two remote sessions of 60 minutes each, within 30 days of the start:

1. **Setup review:** your installation, TLS, OIDC, `ee.admins` and, if you use one, a private
   certificate authority (`backend.trustedCaConfigMap`). Prepare by following
   [Pilot setup](/pilot-setup).
2. **First team workflow:** [sharing](/sharing), [usage limits](/admin#usage-limits), the
   [agent allowlist](/admin#allowed-agents) and
   [MCP restrictions for sessions](/sharing#mcp-restrictions-for-the-whole-session).

You operate your systems yourself, also while sharing your screen; we explain and watch, but do
not take control.

### In scope

- **Installation** of a supported release, with the quickstart or the Helm chart, as described
  on [Install](/getting-started) and [Pilot setup](/pilot-setup): chart values, team login with
  OIDC, object storage, and activating the licence.
- **Upgrades** along the documented path on [Upgrading](/upgrading), including the steps the
  release notes ask for.
- **Documented features of your edition**, as described on these pages and marked Community or
  Enterprise. Features marked experimental, such as the [provider switch](/provider-switching),
  come without production recovery or support guarantees; keep them off in production.
- **Licence questions**: activation, renewal health and seat counts under
  **Settings → License** and **Settings → Users & seats**.

### Not in scope

Unless your order form says otherwise:

- Your Kubernetes cluster, ingress, DNS, certificates, identity provider, Git host, database
  or object storage themselves, beyond the settings Open AgentHub needs from them.
- Errors in the agent CLIs themselves or at the model providers, and your accounts with them; the
  provider's terms apply to your account. In scope, however, is how Open AgentHub integrates the
  CLIs, including regressions with the CLI versions a release pins.
- Modified source code, custom runtime images, and releases older than the current one, where
  the problem is already fixed in a newer release.
- The work agents do in your repositories.

## Reporting a problem

Send what is needed to reproduce the problem, and **nothing that contains secrets or personal
data**. Include:

1. **Versions**: the output of

   ```bash
   helm -n agenthub list
   kubectl -n agenthub get deployment agenthub-backend -o jsonpath='{.spec.template.spec.containers[0].image}'; echo
   ```

2. **What happened**: the steps, what you expected, what you saw, and the time (with time zone).
3. **Edition and agent**: Community or Enterprise, and which agent the session ran (Claude Code,
   Codex, Cursor, OpenClaw or OpenCode).
4. **Pod status**, as pod names and states only:

   ```bash
   kubectl -n agenthub get pods
   ```

**By default, send no logs.** Do not send logs or `kubectl describe` output unless support asks
for a specific excerpt and you have agreed to share it with your provider beforehand; this may
require a data processing agreement. Logs and `describe` output can contain environment values,
events, user names, hostnames and session titles.

**Never send:**

- the API key, personal API tokens, licence tokens, or session access tokens;
- the Secrets `agenthub-data-protection`, `agenthub-api-key`, `postgres-secret` or your Git and
  model provider credentials;
- your values file as it is. If the configuration matters, remove passwords, keys, tokens and
  connection strings first, or name only the values you changed;
- logs, `kubectl describe` output, database dumps, session transcripts or files from a session,
  unless support asks for a specific item and you have agreed this with your provider
  beforehand (this may require a data processing agreement).

If you sent something by mistake, rotate it: a credential that has left your organisation should
be treated as exposed.

A way to collect such a report as one bundle, with secrets removed, will follow. Review that
bundle too before you send it.

## Before you contact support

- [Troubleshooting](/troubleshooting) covers known errors, for example Helm `nil pointer`
  failures and schema lock waits at startup.
- [Upgrading](/upgrading) lists what each release asks of you.
- For licence renewal problems, check [renewal health](/admin#check-renewal-health) first.
