# Evaluation checklist

A checklist for teams evaluating Open AgentHub on their own infrastructure: what to prepare,
the steps from a fresh host to a team signing in, how long each step took when we measured it,
and the limits you should know before you start. It follows the [Install](/getting-started)
page; nothing here replaces it.

The times below were measured in a deliberately slow environment: an emulated virtual machine
(4 vCPU, 10 GB RAM, no hardware acceleration), on release 1.20.0 for the install, the team login
and the first sign-in, and on 1.19.0 for the first session and task. Treat them as upper bounds. On
ordinary hardware with a fast network the quickstart itself takes about a minute.

## Before you start

| You need | Why | Notes |
|---|---|---|
| A Linux host (4 vCPU / 6 GB RAM) or a Kubernetes cluster | The hub, its database and every agent session run there | The quickstart installs a single-node k3s cluster; macOS and Windows use k3d in Docker Desktop |
| Outbound access to the k3s and Helm download sites and `ghcr.io` | The installer and the images come from there | Air-gapped installs were not part of this evaluation |
| A hostname with DNS and a TLS certificate | Single sign-on and sharing need one stable HTTPS address | The certificate must be trusted by browsers. The backend also has to trust the identity provider's certificate: for a private certificate authority, put its PEM bundle in a ConfigMap and set `backend.trustedCaConfigMap` — see [Move the quickstart to team login](/getting-started#move-the-quickstart-to-team-login). Team members' browsers need that authority installed separately |
| An OIDC identity provider | One account per person; groups for Enterprise roles | Public client with PKCE, JWT access tokens for audience `agenthub`, a `preferred_username` claim, refresh tokens (`offline_access`), and a `groups` claim if you want group roles |
| The username of your first administrator | `ee.admins`; nobody is an admin until one is named | Use the identity provider's `preferred_username` |
| Access to your Git host | Agents clone and push with your credentials | A personal access token in Settings → Credentials, or a GitHub/GitLab OAuth app — see [Git](/git) |
| A model account or your own endpoint | Agents need a model | Subscription login, an API key, or your own Messages-API-compatible endpoint — see [Provider login](/provider-login) and [Choosing a model](/models) |
| For Enterprise features: a licence | Sharing, group roles, usage limits, the agent allowlist | Obtained from **Settings → License → Get enterprise license**; see [Admin](/admin) |

## Steps and measured times

| # | Step | What you do | Measured (emulated VM) |
|---|---|---|---|
| 1 | Install | `curl -fsSL https://open-agenthub.github.io/install.sh \| sh` | 5 min 43 s, images pinned to the release |
| 2 | First look | Port-forward, sign in with the generated API key | under a minute |
| 3 | Certificate | Create the TLS Secret for your hostname | seconds |
| 4 | Identity provider | Register the client, redirects and origin ([Install](/getting-started#_2-sign-in)) | depends on your provider; not measured |
| 5 | Team login | One `team-values.yaml` (ingress, `frontendOrigin`, `oidc.*`, `ee.admins`, and `backend.trustedCaConfigMap` for a private certificate authority), one `helm upgrade` — see [Move the quickstart to team login](/getting-started#move-the-quickstart-to-team-login) | 1 min 28 s, including the CA ConfigMap and the TLS Secret |
| 6 | First sign-in | The administrator signs in through the identity provider | 17 s |
| 7 | Enterprise (optional) | Activate the licence under **Settings → License** | seconds once you have a token |
| 8 | First session | Choose agent, billing and repository; start | the first start pulls the agent image (about 500 MB, 2 min 18 s here); later starts reuse it |
| 9 | First task | An interactive task that changes code, runs tests and pushes a branch | 2 min from start to pushed branch with a scripted stand-in model; a real model's time depends on the task |

What can cost time, so you can avoid it:

- **Ingress class.** On the quickstart cluster set `ingress.className=traefik`; the chart's default
  class is not the one k3s runs, and the hub is then not reachable at its hostname.
- **An identity provider that is not reachable yet.** If the backend cannot validate the identity
  provider, it stops with one clear error and is restarted; `helm upgrade --wait` waits until it
  succeeds or its timeout (5 minutes in the documented command) runs out. Make sure the provider
  answers from inside the cluster first, and check
  `kubectl logs -n agenthub deployment/agenthub-backend` early; the previous version keeps serving
  meanwhile.

## The workflow to try

A good first evaluation, with two or three colleagues:

1. The administrator maps identity-provider groups to **admin** or **user**, sets a monthly API
   budget for a group, and limits which agents may be started (**Settings → Usage limits &
   groups**). Enterprise.
2. Create a project and share it with a reviewer as **Viewer**. Enterprise.
3. Start an **Interactive** session from an issue: agent, model, repository and the issue text as
   the task. Answer the first tool approval; **Allow (don't ask again)** covers that tool for the
   rest of the session.
4. The agent works on a branch and pushes it. Opening the pull request needs a token or OAuth app
   that allows it on your Git host.
5. Share the running session with a colleague as **Collaborator**; they find it under **Shared
   with me** and continue the conversation. Enterprise.
6. Switch the session's model between turns from the model menu in the session bar — see
   [Choosing a model](/models).
7. Create a read-only link, open it in a private window, and revoke it. Enterprise.
8. Restrict the session's MCP servers or tools under **MCP security** in the **Share** dialog —
   see [Sharing](/sharing#mcp-restrictions-for-the-whole-session). Enterprise.

## Known limits

- **Enterprise licence.** The checkout under **Settings → License** asks for payment details. There
  is no hosted instance to try.
- **Tool approvals belong to the session owner.** A collaborator can type into a shared session
  but cannot answer its approval prompts; the owner answers them, or allows a tool for the whole
  session.
- **MCP restrictions have limits.** Blocking single tools works for Claude, Codex and OpenCode;
  for Cursor and OpenClaw only whole servers can be blocked. A changed server list applies after
  the session restarts. The restrictions cover MCP only: they do not block network access or
  secrets that the agent can reach from its shell.
- **Sessions created with the quickstart API key** stay with the user `admin` after you switch to
  single sign-on, until an admin hands them to their owner
  ([Hand over data from API-key mode](/admin#hand-over-data-from-api-key-mode)).
- **OpenClaw sessions** do not appear in Slack, Telegram or Signal.
- **The first session start is slow** because the agent image is pulled on first use.

## Roles and editions

| What | Community | Enterprise |
|---|---|---|
| Install, single sign-on, admins named in `ee.admins` | ✓ | ✓ |
| Sessions, projects, model switch, Workspace | ✓ | ✓ |
| Sharing sessions and projects, share links | | ✓ |
| Group roles, usage limits, agent allowlist, seats | | ✓ |
| MCP restrictions per session | | ✓ |

Administrators see **Settings → Admin**; users see their own sessions, those shared with them and
the projects they belong to. See [Admin](/admin) and [Sharing](/sharing).
