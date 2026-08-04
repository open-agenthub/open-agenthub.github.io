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
User Settings → Applications

Redirect URI:  https://<your-host>/api/git/callback/gitlab
Confidential:  yes — the token exchange sends a client secret
Scopes:        api, read_user

"api" is needed to list your projects, "read_user" to identify you.
```

```text [GitHub]
Settings → Developer settings → OAuth Apps

Authorization callback URL:  https://<your-host>/api/git/callback/github
Scopes:                      repo, read:user
```

:::

Leaving `scopes` empty in the values file uses those defaults, so you normally do not set
it at all.

### Self-hosted instances

Set `baseUrl` to the instance root, for example `https://gitlab.example.com`. The authorize,
token, and API endpoints are derived from it.

## Network access

No extra egress configuration is needed for gitlab.com, github.com, or a self-hosted
instance on 443 or 22 — agent pods may already reach those ports. Only a Git server on a
non-standard port needs an entry in `agent.extraEgressPorts`.
