# Connect an MCP client

An external MCP client can create sessions, read their transcripts, and send messages to
your agents. Choose remote HTTP with browser sign-in, or a local stdio process with a
personal API token. Both expose the same tool names.

## Remote HTTP

AgentHub serves MCP at `https://hub.example.com/mcp` using **Streamable HTTP** and
**OAuth 2.1**. AgentHub federates browser sign-in to your instance's OIDC provider.
The endpoint is **off by default**.

### Enable the endpoint

Add this to your Helm values file and apply it using your normal
[upgrade procedure](/upgrading):

```yaml
mcp:
  enabled: true
  publicUrl: "https://hub.example.com"
```

`mcp.publicUrl` is optional when your ingress host already supplies the correct HTTPS
origin. It is the public origin, without `/mcp`, and becomes the OAuth issuer and token
audience. The client and browser must be able to reach it.

Allow `https://hub.example.com/connect/oidc-callback` as a redirect URI for your
instance's OIDC client. This is separate from the web UI's `/auth/callback` URI.

### Connect and authenticate

In Claude Code:

```bash
claude mcp add --transport http agenthub https://hub.example.com/mcp
```

Run `/mcp` and authenticate in the browser. Sign in to the hub and approve the client's
access. Other clients need remote HTTP transport and OAuth support; enter the same endpoint
in their MCP settings. Client registration is automatic, and the authorization flow uses PKCE.
Tools act as the user who approved the client and follow the hub's access checks.

On an instance without OIDC authentication, consent issues a token for the shared `dev`
user. Configure instance authentication before exposing it to other people.

## Local stdio

The stdio server is shipped as source under
[`mcp/agenthub`](https://github.com/open-agenthub/open-agenthub/tree/main/mcp/agenthub)
in the main repository; the package name is `mcp-agenthub`. It uses a personal API token
from **Settings → API tokens**, rather than the remote endpoint's OAuth flow.

Clone the repository locally, then install its dependencies:

```bash
cd open-agenthub/mcp/agenthub
npm ci
```

Configure your MCP client to launch Node with the absolute path to `server.mjs` and set
`AGENTHUB_URL` and `AGENTHUB_TOKEN` in the client's environment configuration:

```json
{
  "mcpServers": {
    "agenthub": {
      "command": "node",
      "args": ["/absolute/path/open-agenthub/mcp/agenthub/server.mjs"],
      "env": {
        "AGENTHUB_URL": "https://hub.example.com",
        "AGENTHUB_TOKEN": "<personal-api-token>"
      }
    }
  }
}
```

Adapt this example to your client's configuration format. The token starts with `oah_`;
keep the real value local. The stdio server calls the token-authenticated API and does not
require `mcp.enabled` or an OIDC browser login.

## First checks

Ask the connected client to list your sessions with `session_list`. Use `session_logs`
or `session_transcript` to read agent output; pod logs primarily show runtime startup.
`agents_list` discovers agents and `agent_send` sends messages. Creating or changing
sessions is a separate action from listing them.

| Symptom | Check |
| --- | --- |
| HTTP 503: MCP endpoint disabled | Enable `mcp.enabled` and apply the Helm values. |
| HTTP 401 on remote HTTP | Complete the client's OAuth sign-in. |
| Identity provider reports `invalid_redirect_uri` | Register the exact public `/connect/oidc-callback` URI. |
| Wrong issuer or unreachable authorization URL | Check `mcp.publicUrl`, ingress and HTTPS reachability. |
| Stdio authentication fails | Check `AGENTHUB_URL` and the personal API token in the client environment. |

MCP controls sessions; [local continuation](/local-sessions) uses separate archive helpers.
For the full tool reference and OAuth endpoints, see the
[MCP server documentation](https://github.com/open-agenthub/open-agenthub/blob/main/docs/mcp-server.md).
