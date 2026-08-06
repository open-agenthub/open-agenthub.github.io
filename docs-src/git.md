# Git integrations

There are two ways to give a session access to your repositories. The manual one works out
of the box; the OAuth one is nicer for more than one user.

## Option 1 — a token or SSH key

Under **Settings → Credentials**, store an SSH private key, or a GitLab/GitHub token, plus
optionally `known_hosts` for the server. Values are written to a per-user Kubernetes
secret, never kept in the database, and never returned by the API.

Inside the session the token is wired up as a git credential helper for HTTPS remotes, and
exported as `GITLAB_TOKEN` so `glab` works. A GitLab token needs `write_repository` for
clone and push, or `api` if you want `glab` to open merge requests.

## Option 2 — connect an account over OAuth

Users click **Connect** on the Account page and authorize once; sessions then clone and
push without anyone handling a token. Tokens are stored in a per-user Kubernetes secret and
refreshed automatically.

### Your callback URL

Register this as the redirect URI at the provider:

```
https://<your-host>/api/git/callback/<provider-id>
```

The last path segment is the `id` you give the provider in the values file — so with
`id: gitlab` and host `hub.your-org.example`:

```
https://hub.your-org.example/api/git/callback/gitlab
```

::: tip Not the same as your login callback
OIDC **login** uses `https://<your-host>/auth/callback`. That is a different thing from Git
account connections. Registering one where the other belongs is the most common mistake
here.
:::

The URL is built from the configured frontend origin, not from the incoming request, so it
stays correct behind a proxy.

### Configure the provider

```yaml
git:
  # Signs the OAuth "state" parameter. Random, 32+ characters, and stable across
  # restarts and replicas — a generated-per-start key breaks the flow on every restart.
  stateKey: "<random 32+ chars>"
  providers:
    - id: gitlab
      type: gitlab          # github | gitlab
      displayName: GitLab
      baseUrl: ""           # e.g. https://gitlab.example.com for self-hosted
      clientId: "<application id>"
      clientSecret: "<secret>"
      scopes: ""            # empty = sensible defaults, see below
```

Apply it with `helm upgrade -f`, and the **Connect** buttons appear on the Account page.
The UI only shows that section when at least one provider has both a client id and a
secret.

### At the provider

::: code-group

```text [GitLab]
User Settings → Applications → Add new application

Redirect URI:  https://<your-host>/api/git/callback/gitlab
Confidential:  yes — the token exchange sends a client secret
Scopes:        tick "api" and "read_user"
```

```text [GitHub]
Settings → Developer settings → OAuth Apps → New OAuth App

Authorization callback URL:  https://<your-host>/api/git/callback/github
Scopes:                      nothing to tick — the request decides
```

:::

::: warning GitLab rejects scopes it was not registered with
GitLab pins the allowed scopes **when you create the application**, and refuses anything
beyond them:

> The requested scope is invalid, unknown, or malformed.

If you see that on the GitLab consent screen, the application is missing a tick — not your
configuration. Open the application in GitLab, tick `api` and `read_user`, save, and try
again. Whatever you tick has to be a superset of what the values file requests.

GitHub works the other way round: an OAuth App declares no scopes up front, so the
authorize request alone decides and this failure mode does not exist there.
:::

Leaving `scopes` empty uses the provider defaults — `api read_user` for GitLab,
`repo read:user` for GitHub — which is enough to browse repositories, clone, and push.

### Scopes for agents that maintain their own repository

If you want sessions to open pull requests, cut releases, and read CI results with `gh`,
the GitHub defaults are not quite enough:

```yaml
scopes: "repo workflow read:org read:user"
```

| Scope | Why |
| --- | --- |
| `repo` | Commits, pushes, releases, and reading Actions runs — all repo-scoped |
| `workflow` | **Required to push any commit that touches `.github/workflows/`.** Without it GitHub rejects the push outright, so an agent cannot change its own CI |
| `read:org` | Lets `gh` see organisation repositories |
| `read:user` | Identifies the account; part of the default |

The narrower GitLab equivalent, if you would rather not grant the broad `api` scope, is
`read_api read_repository write_repository read_user` — tick exactly those in the
application too.

Changing scopes later does not affect accounts that are already connected: existing tokens
keep the scopes they were issued with. Disconnect and reconnect to pick up new ones.

### Making `gh` and `glab` work inside a session

Sessions get their CLI credentials from the git credential store, which is assembled from
the **providers of the repositories attached to that session**. So a session only has an
authenticated `gh` if at least one of its repositories was chosen through the repository
picker — picking it there is what records the provider. A repository typed in as a plain
URL has no provider attached, and `gh` will be unauthenticated even though the account is
connected.

### Self-hosted instances

Set `baseUrl` to the instance root, for example `https://gitlab.example.com`. The authorize,
token, and API endpoints are derived from it.

## Network access

No extra egress configuration is needed for gitlab.com, github.com, or a self-hosted
instance on 443 or 22 — agent pods may already reach those ports. Only a Git server on a
non-standard port needs an entry in `agent.extraEgressPorts`.
