# Support

What support covers, how to reach it, and how to report a problem without handing over
secrets.

**Edition:** Community (public issues) · Enterprise customers (support as agreed in the order
form) · **Who:** operators and administrators of an instance

## Community edition

Report bugs and ask questions as
[GitHub issues](https://github.com/open-agenthub/open-agenthub/issues). Issues are public and
answered on a best-effort basis, without a response time. Do not post logs, values files or
screenshots that contain credentials, hostnames or user content there; see
[Reporting a problem](#reporting-a-problem).

Report suspected vulnerabilities privately to `open-agenthub@mail.on-mb.com`, never as a
public issue.

## Enterprise customers

::: info Channel and response times: set by your order form
How you reach support (YOUR_SUPPORT_CHANNEL), when it is available, and how quickly you get a
response are set by your order form. This page does not define them.
:::

### In scope

- **Installation** of a supported release, with the quickstart or the Helm chart, as described
  on [Install](/getting-started) and [Pilot setup](/pilot-setup): chart values, team login with
  OIDC, object storage, and activating the licence.
- **Upgrades** along the documented path on [Upgrading](/upgrading), including the steps the
  release notes ask for.
- **Documented features of your edition**, as described on these pages and marked Community or
  Enterprise. Features marked experimental, such as the [provider switch](/provider-switching),
  are covered as documented, including their known limits.
- **Licence questions**: activation, renewal health and seat counts under
  **Settings → License** and **Settings → Users & seats**.

### Not in scope

Unless your order form says otherwise:

- Your Kubernetes cluster, ingress, DNS, certificates, identity provider, Git host, database
  or object storage themselves, beyond the settings Open AgentHub needs from them.
- The agent CLIs' own behaviour and your accounts with model providers; Open AgentHub runs the
  CLI versions its release ships, and the provider's terms apply to your account.
- Modified source code, custom runtime images, and releases older than the current one, where
  the problem is already fixed in a newer release.
- The work agents do in your repositories.

## Reporting a problem

Send what is needed to reproduce the problem and leave secrets out. Include:

1. **Versions**: the output of

   ```bash
   helm -n agenthub list
   kubectl -n agenthub get deployment agenthub-backend -o jsonpath='{.spec.template.spec.containers[0].image}'; echo
   ```

2. **What happened**: the steps, what you expected, what you saw, and the time (with time zone).
3. **Edition and agent**: Community or Enterprise, and which agent the session ran (Claude Code,
   Codex, Cursor, OpenClaw or OpenCode).
4. **Pod status**:

   ```bash
   kubectl -n agenthub get pods
   kubectl -n agenthub describe pod POD_NAME
   ```

5. **The backend log around that time**:

   ```bash
   kubectl -n agenthub logs deployment/agenthub-backend --since=30m > backend.log
   ```

   The backend keeps bot tokens and client secrets out of its log. Read the file before you send
   it anyway: it can contain user names, hostnames, repository names and session titles.

**Never send:**

- the API key, personal API tokens, licence tokens, or session access tokens;
- the Secrets `agenthub-data-protection`, `agenthub-api-key`, `postgres-secret` or your Git and
  model provider credentials;
- your values file as it is. If the configuration matters, remove passwords, keys, tokens and
  connection strings first, or name only the values you changed;
- database dumps, session transcripts or files from a session, unless support asks for a
  specific item and you agree to share it.

If you sent something by mistake, rotate it: a credential that has left your organisation should
be treated as exposed.

A way to collect such a report automatically, with secrets removed, is planned.

## Before you contact support

- [Troubleshooting](/troubleshooting) covers known errors, for example Helm `nil pointer`
  failures and schema lock waits at startup.
- [Upgrading](/upgrading) lists what each release asks of you.
- For licence renewal problems, check [renewal health](/admin#check-renewal-health) first.
